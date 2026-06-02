# This converter is written by hand in pure Ruby (no Slim templates).

unless RUBY_ENGINE == 'opal'
  # This converter borrows from the Bespoke converter
  # https://github.com/asciidoctor/asciidoctor-bespoke
  require 'asciidoctor'
end

require 'json'

module Asciidoctor; module Revealjs; end end

class Asciidoctor::Revealjs::Converter < ::Asciidoctor::Converter::Base

  # This module gets mixed in to every node (the context of the conversion) at
  # the time the node is being converted. The properties and methods in this
  # module effectively become direct members of the node.
  module Helpers

    EOL = %(\n)
    SliceHintRx = /  +/

    def slice_text str, active = nil
      if (active || (active.nil? && (option? :slice))) && (str.include? '  ')
        (str.split SliceHintRx).map {|line| %(<span class="line">#{line}</span>) }.join EOL
      else
        str
      end
    end

    def to_boolean val
      val && val != 'false' && val.to_s != '0' || false
    end

    # bool_data_attr
    # If the AsciiDoc attribute doesn't exist, no HTML attribute is added
    # If the AsciiDoc attribute exist and is a true value, HTML attribute is enabled (bool)
    # If the AsciiDoc attribute exist and is a false value, HTML attribute is a false string
    # Ex: a feature is enabled globally but can be disabled using a data- attribute on individual items
    # :revealjs_previewlinks: True
    # then link::example.com[Link text, preview=false]
    # Here the template must have data-preview-link="false" not just no data-preview-link attribute
    def bool_data_attr val
      return false unless attr?(val)
      if attr(val).downcase == 'false' || attr(val) == '0'
        'false'
      else
        true
      end
    end

    # false needs to be verbatim everything else is a string.
    # Calling side isn't responsible for quoting so we are doing it here
    def to_valid_slidenumber val
      # corner case: empty is empty attribute which is true
      return true if val == ""
      # using to_s here handles both the 'false' string and the false boolean
      val.to_s == 'false' ? false : "'#{val}'"
    end

    ##
    # These constants and functions are from the asciidictor-html5s project
    # https://github.com/jirutka/asciidoctor-html5s/blob/a71db48a1dd5196b668b3a3d93693c5d877c5bf3/data/templates/helpers.rb

    # Defaults
    DEFAULT_TOCLEVELS = 2
    DEFAULT_SECTNUMLEVELS = 3


    VOID_ELEMENTS = %w(area base br col command embed hr img input keygen link
                       meta param source track wbr)

    ##
    # Creates an HTML tag with the given name and optionally attributes. Can take
    # a block that will run between the opening and closing tags.
    #
    # @param name [#to_s] the name of the tag.
    # @param attributes [Hash] (default: {})
    # @param content [#to_s] the content; +nil+ to call the block. (default: nil).
    # @yield The block of HTML code within the tag (optional).
    # @return [String] a rendered HTML element.
    #
    def html_tag(name, attributes = {}, content = nil)
      attrs = attributes.inject([]) do |attrs, (k, v)|
        # Join (and reject empties of) array values first so that an array that
        # collapses to nothing is omitted, just like Slim does for class lists.
        v = v.compact.join(' ') if v.is_a? Array
        next attrs unless v && (v == true || !v.nil_or_empty?)
        attrs << (v == true ? k : %(#{k}="#{v}"))
      end
      attrs_str = attrs.empty? ? '' : ' ' + attrs.join(' ')

      if VOID_ELEMENTS.include? name.to_s
        %(<#{name}#{attrs_str}>)
      else
        content ||= (yield if block_given?)
        %(<#{name}#{attrs_str}>#{content}</#{name}>)
      end
    end


    #
    # Extracts data- attributes from the attributes.
    # @param attributes [Hash] (default: {})
    # @return [Hash] a Hash that contains only data- attributes
    #
    def data_attrs(attributes)
      # key can be an Integer (for positional attributes)
      attributes.map { |key, value| (key == 'step') ? ['data-fragment-index', value] : [key, value] }
                .to_h
                .select { |key, _| key.to_s.start_with?('data-') }
    end


    #
    # Wrap an inline text in a <span> element if the node contains a role, an id or data- attributes.
    # @param content [#to_s] the content; +nil+ to call the block. (default: nil).
    # @return [String] the content or the content wrapped in a <span> element as string
    #
    def inline_text_container(content = nil)
      data_attrs = data_attrs(@attributes)
      classes = [role, ('fragment' if (option? :step) || (attr? 'step') || (roles.include? 'step'))].compact
      if !roles.empty? || !data_attrs.empty? || !@id.nil?
        html_tag('span', { :id => @id, :class => classes }.merge(data_attrs), (content || (yield if block_given?)))
      else
        content || (yield if block_given?)
      end
    end


    ##
    # Returns corrected section level.
    #
    # @param sec [Asciidoctor::Section] the section node (default: self).
    # @return [Integer]
    #
    def section_level(sec = self)
      @_section_level ||= (sec.level == 0 && sec.special) ? 1 : sec.level
    end

    ##
    # Display footnotes per slide
    #
    @@slide_footnotes = {}
    @@section_footnotes = {}

    def slide_footnote(footnote)
      footnote_parent = footnote.parent
      # footnotes declared on the section title are processed during the parsing/substitution.
      # as a result, we need to store them to display them on the right slide/section
      if footnote_parent.instance_of?(::Asciidoctor::Section)
        footnote_parent_object_id = footnote_parent.object_id
        section_footnotes = (@@section_footnotes[footnote_parent_object_id] || [])
        footnote_index = section_footnotes.length + 1
        attributes = footnote.attributes.merge({ 'index' => footnote_index })
        inline_footnote = Asciidoctor::Inline.new(footnote_parent, footnote.context, footnote.text, :attributes => attributes)
        section_footnotes << Asciidoctor::Document::Footnote.new(inline_footnote.attr(:index), inline_footnote.id, inline_footnote.text)
        @@section_footnotes[footnote_parent_object_id] = section_footnotes
        inline_footnote
      else
        parent = footnote.parent
        until parent == nil || parent.instance_of?(::Asciidoctor::Section)
          parent = parent.parent
        end
        # check if there is any footnote attached on the section title
        section_footnotes = parent != nil ? @@section_footnotes[parent.object_id] || [] : []
        initial_index = footnote.attr(:index)
        # reset the footnote numbering to 1 on each slide
        # make sure that if a footnote is used more than once it will use the same index/number
        slide_index = (existing_footnote = @@slide_footnotes[initial_index]) ? existing_footnote.index : @@slide_footnotes.length + section_footnotes.length + 1
        attributes = footnote.attributes.merge({ 'index' => slide_index })
        inline_footnote = Asciidoctor::Inline.new(footnote_parent, footnote.context, footnote.text, :attributes => attributes)
        @@slide_footnotes[initial_index] = Asciidoctor::Document::Footnote.new(inline_footnote.attr(:index), inline_footnote.id, inline_footnote.text)
        inline_footnote
      end
    end

    def clear_slide_footnotes
      @@slide_footnotes = {}
    end

    def slide_footnotes(section)
      section_object_id = section.object_id
      section_footnotes = @@section_footnotes[section_object_id] || []
      section_footnotes + @@slide_footnotes.values
    end

    ##
    # Returns the captioned section's title, optionally numbered.
    #
    # @param sec [Asciidoctor::Section] the section node (default: self).
    # @return [String]
    #
    def section_title(sec = self)
      sectnumlevels = document.attr(:sectnumlevels, DEFAULT_SECTNUMLEVELS).to_i

      if sec.numbered && !sec.caption && sec.level <= sectnumlevels
        [sec.sectnum, sec.captioned_title].join(' ')
      else
        sec.captioned_title
      end
    end

    # Retrieves the built-in html5 converter.
    #
    # Returns the instance of the Asciidoctor::Converter::Html5Converter
    # associated with this node.
    def html5_converter
      converter.instance_variable_get("@delegate_converter")
    end

    def convert_inline_image(node = self)
      target = node.target
      if (node.type || 'image') == 'icon'
        if (icons = node.document.attr 'icons') == 'font'
          i_class_attr_val = %(#{node.attr(:set, 'fa')} fa-#{target})
          i_class_attr_val = %(#{i_class_attr_val} fa-#{node.attr 'size'}) if node.attr? 'size'
          if node.attr? 'flip'
            i_class_attr_val = %(#{i_class_attr_val} fa-flip-#{node.attr 'flip'})
          elsif node.attr? 'rotate'
            i_class_attr_val = %(#{i_class_attr_val} fa-rotate-#{node.attr 'rotate'})
          end
          attrs = (node.attr? 'title') ? %( title="#{node.attr 'title'}") : ''
          img = %(<i class="#{i_class_attr_val}"#{attrs}></i>)
        elsif icons
          attrs = (node.attr? 'width') ? %( width="#{node.attr 'width'}") : ''
          attrs = %(#{attrs} height="#{node.attr 'height'}") if node.attr? 'height'
          attrs = %(#{attrs} title="#{node.attr 'title'}") if node.attr? 'title'
          img = %(<img src="#{src = node.icon_uri target}" alt="#{encode_attribute_value node.alt}"#{attrs}>)
        else
          img = %([#{node.alt}&#93;)
        end
      else
        html_attrs = (node.attr? 'width') ? %( width="#{node.attr 'width'}") : ''
        html_attrs = %(#{html_attrs} height="#{node.attr 'height'}") if node.attr? 'height'
        html_attrs = %(#{html_attrs} title="#{node.attr 'title'}") if node.attr? 'title'
        img, src = img_tag(node, target, html_attrs)
      end
      img_link(node, src, img)
    end

    def convert_image(node = self)
      # When the stretch class is present, block images will take the most space
      # they can take. Setting width and height can override that.
      # We pinned the 100% to height to avoid aspect ratio breakage and since
      # widescreen monitors are the most popular, chances are that height will
      # be the biggest constraint
      if node.has_role?('stretch') && !(node.attr?(:width) || node.attr?(:height))
        height_value = "100%"
      elsif node.attr? 'height'
        height_value = node.attr 'height'
      else
        height_value = nil
      end
      html_attrs = (node.attr? 'width') ? %( width="#{node.attr 'width'}") : ''
      html_attrs = %(#{html_attrs} height="#{height_value}") if height_value
      html_attrs = %(#{html_attrs} title="#{node.attr 'title'}") if node.attr? 'title'
      html_attrs = %(#{html_attrs} style="background: #{node.attr :background}") if node.attr? 'background'
      img, src = img_tag(node, node.attr('target'), html_attrs)
      img_link(node, src, img)
    end

    def img_tag(node = self, target, html_attrs)
      if ((node.attr? 'format', 'svg') || (target.include? '.svg')) && node.document.safe < ::Asciidoctor::SafeMode::SECURE
        if node.option? 'inline'
          img = (html5_converter.read_svg_contents node, target) || %(<span class="alt">#{node.alt}</span>)
        elsif node.option? 'interactive'
          fallback = (node.attr? 'fallback') ? %(<img src="#{node.image_uri node.attr 'fallback'}" alt="#{encode_attribute_value node.alt}"#{html_attrs}>) : %(<span class="alt">#{node.alt}</span>)
          img = %(<object type="image/svg+xml" data="#{src = node.image_uri target}"#{html_attrs}>#{fallback}</object>)
        else
          img = %(<img src="#{src = node.image_uri target}" alt="#{encode_attribute_value node.alt}"#{html_attrs}>)
        end
      else
        img = %(<img src="#{src = node.image_uri target}" alt="#{encode_attribute_value node.alt}"#{html_attrs}>)
      end

      [img, src]
    end

    # Wrap the <img> element in a <a> element if the link attribute is defined
    def img_link(node = self, src, content)
      if (node.attr? 'link') && ((href_attr_val = node.attr 'link') != 'self' || (href_attr_val = src))
        if (link_preview_value = bool_data_attr :link_preview)
          data_preview_attr = %( data-preview-link="#{link_preview_value == true ? "" : link_preview_value}")
        end
        return %(<a class="image" href="#{href_attr_val}"#{(append_link_constraint_attrs node).join}#{data_preview_attr}>#{content}</a>)
      end

      content
    end

    def revealjs_dependencies(document, node, revealjsdir)
      dependencies = []
      dependencies << "{ src: '#{revealjsdir}/plugin/zoom/zoom.js', async: true, callback: function () { Reveal.registerPlugin(RevealZoom) } }" unless (node.attr? 'revealjs_plugin_zoom', 'disabled')
      dependencies << "{ src: '#{revealjsdir}/plugin/notes/notes.js', async: true, callback: function () { Reveal.registerPlugin(RevealNotes) } }" unless (node.attr? 'revealjs_plugin_notes', 'disabled')
      dependencies << "{ src: '#{revealjsdir}/plugin/search/search.js', async: true, callback: function () { Reveal.registerPlugin(RevealSearch) } }" if (node.attr? 'revealjs_plugin_search', 'enabled')
      dependencies.join(",\n      ")
    end

    # Between delimiters (--) is code taken from asciidoctor-bespoke 1.0.0.alpha.1
    # Licensed under MIT, Copyright (C) 2015-2016 Dan Allen and the Asciidoctor Project
    #--
    # Retrieve the converted content, wrap it in a `<p>` element if
    # the content_model equals :simple and return the result.
    #
    # Returns the block content as a String, wrapped inside a `<p>` element if
    # the content_model equals `:simple`.
    def resolve_content
      @content_model == :simple ? %(<p>#{content}</p>) : content
    end

    # Copied from asciidoctor/lib/asciidoctor/converter/html5.rb (method is private)
    def append_link_constraint_attrs node, attrs = []
      rel = 'nofollow' if node.option? 'nofollow'
      if (window = node.attributes['window'])
        attrs << %( target="#{window}")
        attrs << (rel ? %( rel="#{rel} noopener") : ' rel="noopener"') if window == '_blank' || (node.option? 'noopener')
      elsif rel
        attrs << %( rel="#{rel}")
      end
      attrs
    end

    # Copied from asciidoctor/lib/asciidoctor/converter/html5.rb (method is private)
    def encode_attribute_value val
      (val.include? '"') ? (val.gsub '"', '&quot;') : val
    end

    # Copied from asciidoctor/lib/asciidoctor/converter/semantic-html5.rb which is not yet shipped
    # @todo remove this code when the new converter becomes available in the main gem
    def generate_authors node
      return if node.authors.empty?

      if node.authors.length == 1
        # NOTE: the two-space indentation is kept to preserve byte-for-byte
        # compatibility with the output produced by the former Slim pipeline.
        %(<p class="byline">
  #{format_author node, node.authors.first}
  </p>)
      else
        result = ['<ul class="byline">']
        node.authors.each do |author|
          result << "<li>#{format_author node, author}</li>"
        end
        result << '</ul>'
        result.join Asciidoctor::LF
      end
    end

    # Copied from asciidoctor/lib/asciidoctor/converter/semantic-html5.rb which is not yet shipped
    # @todo remove this code when the new converter becomes available in the main gem
    def format_author node, author
      in_context 'author' do
        %(<span class="author">#{node.sub_replacements author.name}#{author.email ? %( #{node.sub_macros author.email}) : ''}</span>)
      end
    end

    # Copied from asciidoctor/lib/asciidoctor/converter/semantic-html5.rb which is not yet shipped
    # @todo remove this code when the new converter becomes available in the main gem
    def in_context name
      (@convert_context ||= []).push name
      result = yield
      @convert_context.pop
      result
    end

    STEM_EQNUMS_AMS = 'ams'
    STEM_EQNUMS_NONE = 'none'
    STEM_EQNUMS_VALID_VALUES = [
      STEM_EQNUMS_NONE,
      STEM_EQNUMS_AMS,
      'all'
    ]

    MATHJAX_VERSION = '3.2.0'

    # Generate the Mathjax markup to process STEM expressions
    # @param cdn_base [String]
    # @return [String]
    def generate_stem(cdn_base)
      if attr?(:stem)
        eqnums_val = attr('eqnums', STEM_EQNUMS_NONE).downcase
        unless STEM_EQNUMS_VALID_VALUES.include?(eqnums_val)
          eqnums_val = STEM_EQNUMS_AMS
        end
        mathjax_configuration = {
          tex: {
            inlineMath: [Asciidoctor::INLINE_MATH_DELIMITERS[:latexmath]],
            displayMath: [Asciidoctor::BLOCK_MATH_DELIMITERS[:latexmath]],
            processEscapes: false,
            tags: eqnums_val,
          },
          options: {
            ignoreHtmlClass: 'nostem|nolatexmath'
          },
          asciimath: {
            delimiters: [Asciidoctor::BLOCK_MATH_DELIMITERS[:asciimath]],
          },
          loader: {
            load: ['input/asciimath', 'output/chtml', 'ui/menu']
          }
        }
        mathjaxdir = attr('mathjaxdir', "#{cdn_base}/mathjax/#{MATHJAX_VERSION}/es5")
        %(<script>window.MathJax = #{JSON.generate(mathjax_configuration)};</script>) +
        %(<script async src="#{mathjaxdir}/tex-mml-chtml.js"></script>)
      end
    end
    #--

    # Generate the <script> block that works around the reveal.js limitation
    # "Only direct descendants of a slide section can be stretched".
    # See https://github.com/hakimel/reveal.js/issues/2584
    # @return [String]
    def stretch_nested_elements_script
      width = attr 'revealjs_width', 960
      height = attr 'revealjs_height', 700
      %(<script>) + <<~JS.chomp + %(</script>)
        var dom = {};
        dom.slides = document.querySelector('.reveal .slides');

        function getRemainingHeight(element, slideElement, height) {
          height = height || 0;
          if (element) {
            var newHeight, oldHeight = element.style.height;
            // Change the .stretch element height to 0 in order find the height of all
            // the other elements
            element.style.height = '0px';
            // In Overview mode, the parent (.slide) height is set of 700px.
            // Restore it temporarily to its natural height.
            slideElement.style.height = 'auto';
            newHeight = height - slideElement.offsetHeight;
            // Restore the old height, just in case
            element.style.height = oldHeight + 'px';
            // Clear the parent (.slide) height. .removeProperty works in IE9+
            slideElement.style.removeProperty('height');
            return newHeight;
          }
          return height;
        }

        function layoutSlideContents(width, height) {
          // Handle sizing of elements with the 'stretch' class
          toArray(dom.slides.querySelectorAll('section .stretch')).forEach(function (element) {
            // Determine how much vertical space we can use
            var limit = 5; // hard limit
            var parent = element.parentNode;
            while (parent.nodeName !== 'SECTION' && limit > 0) {
              parent = parent.parentNode;
              limit--;
            }
            if (limit === 0) {
              // unable to find parent, aborting!
              return;
            }
            var remainingHeight = getRemainingHeight(element, parent, height);
            // Consider the aspect ratio of media elements
            if (/(img|video)/gi.test(element.nodeName)) {
              var nw = element.naturalWidth || element.videoWidth, nh = element.naturalHeight || element.videoHeight;
              var es = Math.min(width / nw, remainingHeight / nh);
              element.style.width = (nw * es) + 'px';
              element.style.height = (nh * es) + 'px';
            } else {
              element.style.width = width + 'px';
              element.style.height = remainingHeight + 'px';
            }
          });
        }

        function toArray(o) {
          return Array.prototype.slice.call(o);
        }

        Reveal.addEventListener('slidechanged', function () {
          layoutSlideContents(#{width}, #{height})
        });
        Reveal.addEventListener('ready', function () {
          layoutSlideContents(#{width}, #{height})
        });
        Reveal.addEventListener('resize', function () {
          layoutSlideContents(#{width}, #{height})
        });
      JS
    end
  end

  # Make Helpers' constants accessible from the conversion methods.
  Helpers.constants.each do |const|
    const_set(const, Helpers.const_get(const))
  end


  register_for "revealjs", "reveal.js"

  def initialize(backend, opts = {})
    super
    basebackend "html" if respond_to? :basebackend
    outfilesuffix ".html" if respond_to? :outfilesuffix
    filetype "html" if respond_to? :filetype
    supports_templates if respond_to? :supports_templates

    delegate_backend = (opts[:delegate_backend] || "html5").to_s
    factory = ::Asciidoctor::Converter::Factory

    converter = factory.create(delegate_backend, backend_info)
    @delegate_converter = if converter == self
      factory.new.create(delegate_backend, backend_info)
    else
      converter
    end
  end

  def convert(node, transform = nil, opts = {})
    meth_name = "convert_#{transform || node.node_name}"
    opts ||= {}
    converter = respond_to?(meth_name) ? self : @delegate_converter

    if opts.empty?
      converter.send(meth_name, node)
    else
      converter.send(meth_name, node, opts)
    end
  end

  # Mix the Helpers into the node and evaluate the given block with the node as
  # +self+ (the same context the templates used to run in).
  def render(node, &block)
    node.extend(Helpers)
    node.instance_eval(&block)
  end

  def convert_admonition(node, opts = {})
    render(node) do
      if (has_role? 'aside') || (has_role? 'speaker') || (has_role? 'notes')
        %(<aside class="notes">#{resolve_content}</aside>)
      else
        html_tag('div', { :id => @id, :class => ['admonitionblock', (attr :name), role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do
          icon = if @document.attr? :icons, 'font'
            icon_mapping = { 'caution' => 'fire', 'important' => 'exclamation-circle', 'note' => 'info-circle', 'tip' => 'lightbulb-o', 'warning' => 'warning' }
            html_tag('i', class: %(fa fa-#{icon_mapping[attr :name]}), title: (attr :textlabel || @caption))
          elsif @document.attr? :icons
            html_tag('img', src: icon_uri(attr :name), alt: @caption)
          else
            %(<div class="title">#{(attr :textlabel) || @caption}</div>)
          end
          cell = +''
          cell << %(<div class="title">#{title}</div>) if title?
          cell << content.to_s
          %(<table><tr><td class="icon">#{icon}</td><td class="content">#{cell}</td></tr></table>)
        end
      end
    end
  end

  def convert_audio(node, opts = {})
    render(node) do
      html_tag('div', { :id => @id, :class => ['audioblock', @style, role] }.merge(data_attrs(@attributes))) do
        buf = +''
        buf << %(<div class="title">#{captioned_title}</div>) if title?
        buf << %(<div class="content">)
        buf << html_tag('audio', src: media_uri(attr :target), autoplay: (option? 'autoplay'), controls: !(option? 'nocontrols'), loop: (option? 'loop')) do
          'Your browser does not support the audio tag.'
        end
        buf << %(</div>)
        buf
      end
    end
  end

  def convert_colist(node, opts = {})
    render(node) do
      html_tag('div', { :id => @id, :class => ['colist', @style, role] }.merge(data_attrs(@attributes))) do
        buf = +''
        buf << %(<div class="title">#{title}</div>) if title?
        if @document.attr? :icons
          font_icons = @document.attr? :icons, 'font'
          buf << '<table>'
          items.each_with_index do |item, i|
            num = i + 1
            buf << html_tag('tr', class: ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step'))) do
              cell = '<td>'
              if font_icons
                cell << html_tag('i', class: 'conum', 'data-value' => num)
                cell << %(<b>#{num}</b>)
              else
                cell << html_tag('img', src: icon_uri("callouts/#{num}"), alt: num)
              end
              cell << %(</td><td>#{item.text}</td>)
              cell
            end
          end
          buf << '</table>'
        else
          buf << '<ol>'
          items.each do |item|
            buf << html_tag('li', class: ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step'))) do
              %(<p>#{item.text}</p>)
            end
          end
          buf << '</ol>'
        end
        buf
      end
    end
  end

  def convert_dlist(node, opts = {})
    render(node) do
      case @style
      when 'qanda'
        html_tag('div', { :id => @id, :class => ['qlist', @style, role] }.merge(data_attrs(@attributes))) do
          buf = +''
          buf << %(<div class="title">#{title}</div>) if title?
          buf << '<ol>'
          items.each do |questions, answer|
            buf << '<li>'
            [*questions].each do |question|
              buf << %(<p><em>#{question.text}</em></p>)
            end
            unless answer.nil?
              buf << %(<p>#{answer.text}</p>) if answer.text?
              buf << answer.content.to_s if answer.blocks?
            end
            buf << '</li>'
          end
          buf << '</ol>'
          buf
        end
      when 'horizontal'
        html_tag('div', { :id => @id, :class => ['hdlist', role] }.merge(data_attrs(@attributes))) do
          buf = +''
          buf << %(<div class="title">#{title}</div>) if title?
          buf << '<table>'
          if (attr? :labelwidth) || (attr? :itemwidth)
            buf << '<colgroup>'
            buf << html_tag('col', style: ((attr? :labelwidth) ? %(width:#{(attr :labelwidth).chomp '%'}%;) : nil))
            buf << html_tag('col', style: ((attr? :itemwidth) ? %(width:#{(attr :itemwidth).chomp '%'}%;) : nil))
            buf << '</colgroup>'
          end
          items.each do |terms, dd|
            buf << '<tr>'
            buf << html_tag('td', class: ['hdlist1', ('strong' if option? 'strong')]) do
              cell = +''
              terms = [*terms]
              last_term = terms.last
              terms.each do |dt|
                cell << dt.text.to_s
                cell << '<br>' if dt != last_term
              end
              cell
            end
            buf << '<td class="hdlist2">'
            unless dd.nil?
              buf << %(<p>#{dd.text}</p>) if dd.text?
              buf << dd.content.to_s if dd.blocks?
            end
            buf << '</td></tr>'
          end
          buf << '</table>'
          buf
        end
      else
        html_tag('div', { :id => @id, :class => ['dlist', @style, role] }.merge(data_attrs(@attributes))) do
          buf = +''
          buf << %(<div class="title">#{title}</div>) if title?
          buf << '<dl>'
          items.each do |terms, dd|
            [*terms].each do |dt|
              buf << html_tag('dt', class: ('hdlist1' unless @style)) { dt.text }
            end
            unless dd.nil?
              buf << '<dd>'
              buf << %(<p>#{dd.text}</p>) if dd.text?
              buf << dd.content.to_s if dd.blocks?
              buf << '</dd>'
            end
          end
          buf << '</dl>'
          buf
        end
      end
    end
  end

  def convert_embedded(node, opts = {})
    render(node) do
      buf = +''
      unless notitle || !has_header?
        buf << html_tag('h1', id: @id) { @header.title }
      end
      buf << content.to_s
      unless !footnotes? || attr?(:nofootnotes)
        buf << %(<div id="footnotes"><hr>)
        footnotes.each do |fn|
          buf << %(<div class="footnote" id="_footnote_#{fn.index}"><a href="#_footnoteref_#{fn.index}">#{fn.index}</a>. #{fn.text}</div>)
        end
        buf << %(</div>)
      end
      buf
    end
  end

  def convert_example(node, opts = {})
    render(node) do
      html_tag('div', { :id => @id, :class => ['exampleblock', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do
        buf = +''
        buf << %(<div class="title">#{captioned_title}</div>) if title?
        buf << %(<div class="content">#{content}</div>)
        buf
      end
    end
  end

  def convert_floating_title(node, opts = {})
    render(node) do
      html_tag("h#{level + 1}", id: id, class: [style, role]) { title }
    end
  end

  def convert_image(node, opts = {})
    render(node) do
      next '' if attributes[1] == 'background' || attributes[1] == 'canvas'
      inline_style = [("text-align: #{attr :align}" if attr? :align), ("float: #{attr :float}" if attr? :float)].compact.join('; ')
      buf = html_tag('div', { :id => @id, :class => ['imageblock', role, ('fragment' if (option? :step) || (attr? 'step'))], :style => inline_style }.merge(data_attrs(@attributes))) do
        convert_image
      end
      buf << %(<div class="title">#{captioned_title}</div>) if title?
      buf
    end
  end

  def convert_inline_anchor(node, opts = {})
    render(node) do
      case @type
      when :xref
        refid = (attr :refid) || @target
        html_tag('a', { :href => @target, :class => [role, ('fragment' if (option? :step) || (attr? 'step'))].compact }.merge(data_attrs(@attributes))) do
          (@text || @document.references[:ids].fetch(refid, "[#{refid}]")).tr_s("\n", ' ')
        end
      when :ref
        html_tag('a', { :id => @target }.merge(data_attrs(@attributes)))
      when :bibref
        html_tag('a', { :id => @target }.merge(data_attrs(@attributes))) + %([#{@target}])
      else
        html_tag('a', { :href => @target, :class => [role, ('fragment' if (option? :step) || (attr? 'step'))].compact, :target => (attr :window), 'data-preview-link' => (bool_data_attr :preview) }.merge(data_attrs(@attributes))) do
          @text
        end
      end
    end
  end

  def convert_inline_break(node, opts = {})
    render(node) do
      %(#{@text}<br>)
    end
  end

  def convert_inline_button(node, opts = {})
    render(node) do
      html_tag('b', { :class => ['button'] }.merge(data_attrs(@attributes))) { @text }
    end
  end

  def convert_inline_callout(node, opts = {})
    render(node) do
      if @document.attr? :icons, 'font'
        %(#{html_tag('i', class: 'conum', 'data-value' => @text)}<b>(#{@text})</b>)
      elsif @document.attr? :icons
        html_tag('img', src: icon_uri("callouts/#{@text}"), alt: @text)
      else
        %(<b>(#{@text})</b>)
      end
    end
  end

  def convert_inline_footnote(node, opts = {})
    render(node) do
      footnote = slide_footnote(self)
      index = footnote.attr(:index)
      id = footnote.id
      if @type == :xref
        html_tag('sup', { :class => ['footnoteref'] }.merge(data_attrs(footnote.attributes))) do
          %([<span class="footnote" title="View footnote.">#{index}</span>])
        end
      else
        html_tag('sup', { :id => ("_footnote_#{id}" if id), :class => ['footnote'] }.merge(data_attrs(footnote.attributes))) do
          %([<span class="footnote" title="View footnote.">#{index}</span>])
        end
      end
    end
  end

  def convert_inline_image(node, opts = {})
    render(node) do
      html_tag('span', { :class => [@type, role, ('fragment' if (option? :step) || (attr? 'step'))], :style => ("float: #{attr :float}" if attr? :float) }.merge(data_attrs(@attributes))) do
        convert_inline_image
      end
    end
  end

  def convert_inline_indexterm(node, opts = {})
    render(node) do
      @type == :visible ? @text : ''
    end
  end

  def convert_inline_kbd(node, opts = {})
    render(node) do
      if (keys = attr 'keys').size == 1
        html_tag('kbd', data_attrs(@attributes)) { keys.first }
      else
        html_tag('span', { :class => ['keyseq'] }.merge(data_attrs(@attributes))) do
          buf = +''
          keys.each_with_index do |key, idx|
            buf << '+' unless idx.zero?
            buf << %(<kbd>#{key}</kbd>)
          end
          buf
        end
      end
    end
  end

  def convert_inline_menu(node, opts = {})
    render(node) do
      menu = attr 'menu'
      menuitem = attr 'menuitem'
      if !(submenus = attr 'submenus').empty?
        html_tag('span', { :class => ['menuseq'] }.merge(data_attrs(@attributes))) do
          %(<span class="menu">#{menu}</span>&#160;&#9656;&#32;) +
            submenus.map {|submenu| %(<span class="submenu">#{submenu}</span>&#160;&#9656;&#32;) }.join +
            %(<span class="menuitem">#{menuitem}</span>)
        end
      elsif !menuitem.nil?
        html_tag('span', { :class => ['menuseq'] }.merge(data_attrs(@attributes))) do
          %(<span class="menu">#{menu}</span>&#160;&#9656;&#32;<span class="menuitem">#{menuitem}</span>)
        end
      else
        html_tag('span', { :class => ['menu'] }.merge(data_attrs(@attributes))) { menu }
      end
    end
  end

  def convert_inline_quoted(node, opts = {})
    render(node) do
      quote_tags = { emphasis: 'em', strong: 'strong', monospaced: 'code', superscript: 'sup', subscript: 'sub' }
      if (quote_tag = quote_tags[@type])
        html_tag(quote_tag, { :id => @id, :class => [role, ('fragment' if (option? :step) || (attr? 'step'))].compact }.merge(data_attrs(@attributes)), @text)
      else
        case @type
        when :double
          inline_text_container("&#8220;#{@text}&#8221;")
        when :single
          inline_text_container("&#8216;#{@text}&#8217;")
        when :asciimath, :latexmath
          open, close = Asciidoctor::INLINE_MATH_DELIMITERS[@type]
          inline_text_container("#{open}#{@text}#{close}")
        else
          inline_text_container(@text)
        end
      end
    end
  end

  def convert_listing(node, opts = {})
    render(node) do
      nowrap = (option? 'nowrap') || !(document.attr? 'prewrap')
      if @style == 'source'
        syntax_hl = document.syntax_highlighter
        lang = attr :language
        if syntax_hl
          doc_attrs = document.attributes
          css_mode = (doc_attrs[%(#{syntax_hl.name}-css)] || :class).to_sym
          style = doc_attrs[%(#{syntax_hl.name}-style)]
          hl_opts = syntax_hl.highlight? ? { css_mode: css_mode, style: style } : {}
          hl_opts[:nowrap] = nowrap
        end
      end
      # data-id must not be declared on the <div> element (but on the <pre> element for auto-animate)
      html_tag('div', { :id => id, :class => ['listingblock', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes.reject {|key, _| key == 'data-id' }))) do
        buf = +''
        buf << %(<div class="title">#{captioned_title}</div>) if title?
        buf << %(<div class="content">)
        if syntax_hl
          buf << (syntax_hl.format self, lang, hl_opts).to_s
        elsif @style == 'source'
          buf << html_tag('pre', class: ['highlight', ('nowrap' if nowrap)]) do
            html_tag('code', { class: [("language-#{lang}" if lang)], 'data-lang' => ("#{lang}" if lang) }, content || '')
          end
        else
          buf << html_tag('pre', { class: [('nowrap' if nowrap)] }, content || '')
        end
        buf << %(</div>)
        buf
      end
    end
  end

  def convert_literal(node, opts = {})
    render(node) do
      html_tag('div', { :id => id, :class => ['literalblock', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do
        buf = +''
        buf << %(<div class="title">#{title}</div>) if title?
        buf << %(<div class="content">)
        buf << html_tag('pre', { class: (!(@document.attr? :prewrap) || (option? 'nowrap') ? 'nowrap' : nil) }, content)
        buf << %(</div>)
        buf
      end
    end
  end

  def convert_notes(node, opts = {})
    render(node) do
      %(<aside class="notes">#{resolve_content}</aside>)
    end
  end

  def convert_olist(node, opts = {})
    render(node) do
      html_tag('div', { :id => @id, :class => ['olist', @style, role] }.merge(data_attrs(@attributes))) do
        buf = +''
        buf << %(<div class="title">#{title}</div>) if title?
        buf << html_tag('ol', class: @style, start: (attr :start), type: list_marker_keyword) do
          inner = +''
          items.each do |item|
            inner << html_tag('li', class: ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step'))) do
              li = %(<p>#{item.text}</p>)
              li << item.content.to_s if item.blocks?
              li
            end
          end
          inner
        end
        buf
      end
    end
  end

  def convert_open(node, opts = {})
    render(node) do
      if @style == 'abstract'
        if @parent == @document && @document.doctype == 'book'
          puts 'asciidoctor: WARNING: abstract block cannot be used in a document without a title when doctype is book. Excluding block content.'
          ''
        else
          html_tag('div', { :id => @id, :class => ['quoteblock', 'abstract', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do
            buf = +''
            buf << %(<div class="title">#{title}</div>) if title?
            buf << %(<blockquote>#{content}</blockquote>)
            buf
          end
        end
      elsif @style == 'partintro' && (@level != 0 || @parent.context != :section || @document.doctype != 'book')
        puts 'asciidoctor: ERROR: partintro block can only be used when doctype is book and it\'s a child of a book part. Excluding block content.'
        ''
      elsif (has_role? 'aside') or (has_role? 'speaker') or (has_role? 'notes')
        %(<aside class="notes">#{resolve_content}</aside>)
      else
        html_tag('div', { :id => @id, :class => ['openblock', (@style != 'open' ? @style : nil), role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do
          buf = +''
          buf << %(<div class="title">#{title}</div>) if title?
          buf << %(<div class="content">#{content}</div>)
          buf
        end
      end
    end
  end

  def convert_outline(node, opts = {})
    render(node) do
      next '' if sections.empty?
      toclevels = (opts[:toclevels] if opts) || (document.attr 'toclevels', DEFAULT_TOCLEVELS).to_i
      slevel = section_level sections.first
      buf = %(<ol class="sectlevel#{slevel}">)
      sections.each do |sec|
        buf << %(<li><a href="##{sec.id}">#{section_title sec}</a>)
        if (sec.level < toclevels) && (child_toc = converter.convert sec, 'outline')
          buf << child_toc.to_s
        end
        buf << '</li>'
      end
      buf << '</ol>'
      buf
    end
  end

  def convert_page_break(node, opts = {})
    render(node) do
      %(<div style="page-break-after: always;"></div>)
    end
  end

  def convert_paragraph(node, opts = {})
    render(node) do
      html_tag('div', { :id => @id, :class => ['paragraph', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do
        buf = +''
        buf << %(<div class="title">#{title}</div>) if title?
        buf << (has_role?('small') ? %(<small>#{content}</small>) : %(<p>#{content}</p>))
        buf
      end
    end
  end

  def convert_pass(node, opts = {})
    render(node) do
      content.to_s
    end
  end

  def convert_preamble(node, opts = {})
    # preamble is shown on the title slide which is rendered by the document method
    ''
  end

  def convert_quote(node, opts = {})
    render(node) do
      html_tag('div', { :id => @id, :class => ['quoteblock', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do
        buf = +''
        buf << %(<div class="title">#{title}</div>) if title?
        buf << %(<blockquote>#{content}</blockquote>)
        attribution = (attr? :attribution) ? (attr :attribution) : nil
        citetitle = (attr? :citetitle) ? (attr :citetitle) : nil
        if attribution || citetitle
          buf << %(<div class="attribution">)
          buf << %(<cite>#{citetitle}</cite>) if citetitle
          if attribution
            buf << '<br>' if citetitle
            buf << %(&#8212; #{attribution})
          end
          buf << %(</div>)
        end
        buf
      end
    end
  end

  def convert_ruler(node, opts = {})
    render(node) do
      '<hr>'
    end
  end

  def convert_section(node, opts = {})
    render(node) do
      # OPTIONS PROCESSING
      # hide slides on %conceal, %notitle and named "!"
      titleless = (title = self.title) == '!'
      hide_title = (titleless || (option? :notitle) || (option? :conceal))

      vertical_slides = find_by(context: :section) {|section| section.level == 2 }

      # extracting block image attributes to find an image to use as a background_image attribute
      data_background_image = data_background_size = data_background_repeat = data_background_position = data_background_transition = nil
      data_background_video = data_background_color = nil

      # process the first image block in the current section that acts as a background
      section_images = blocks.map do |block|
        if (ctx = block.context) == :image
          ['background', 'canvas'].include?(block.attributes[1]) ? block : []
        elsif ctx == :section
          []
        else
          block.find_by(context: :image) {|image| ['background', 'canvas'].include?(image.attributes[1]) } || []
        end
      end
      if (bg_image = section_images.flatten.first)
        data_background_image = image_uri(bg_image.attr 'target')
        # make sure no crash on nil and default values make sense
        data_background_size = bg_image.attr 'size'
        data_background_repeat = bg_image.attr 'repeat'
        data_background_transition = bg_image.attr 'transition'
        data_background_position = bg_image.attr 'position'
      end

      # background-image section attribute overrides the image one
      data_background_image = image_uri(attr 'background-image') if attr? 'background-image'
      data_background_video = media_uri(attr 'background-video') if attr? 'background-video'
      data_background_color = attr 'background-color' if attr? 'background-color'

      parent_section_with_vertical_slides = @level == 1 && !vertical_slides.empty?

      footnotes = lambda do
        slide_fn = slide_footnotes(self)
        if document.footnotes? && !(parent.attr? 'nofootnotes') && !slide_fn.empty?
          %(<div class="footnotes">) +
            slide_fn.map {|footnote| %(<div class="footnote">#{footnote.index}. #{footnote.text}</div>) }.join +
            %(</div>)
        else
          ''
        end
      end

      section = lambda do
        buf = html_tag('section', {
          :id => (titleless ? nil : id),
          :class => roles,
          'data-background-gradient' => (attr "background-gradient"),
          'data-transition' => (attr 'transition'),
          'data-transition-speed' => (attr 'transition-speed'),
          'data-background-color' => data_background_color,
          'data-background-image' => data_background_image,
          'data-background-size' => (data_background_size || attr('background-size')),
          'data-background-repeat' => (data_background_repeat || attr('background-repeat')),
          'data-background-transition' => (data_background_transition || attr('background-transition')),
          'data-background-position' => (data_background_position || attr('background-position')),
          'data-background-iframe' => (attr "background-iframe"),
          'data-background-video' => data_background_video,
          'data-background-video-loop' => ((attr? 'background-video-loop') || (option? 'loop')),
          'data-background-video-muted' => ((attr? 'background-video-muted') || (option? 'muted')),
          'data-background-opacity' => (attr "background-opacity"),
          'data-autoslide' => (attr "autoslide"),
          'data-state' => (attr 'state'),
          'data-auto-animate' => ((attr? 'auto-animate') || (option? 'auto-animate')),
          'data-auto-animate-easing' => ((attr 'auto-animate-easing') || (option? 'auto-animate-easing')),
          'data-auto-animate-unmatched' => ((attr 'auto-animate-unmatched') || (option? 'auto-animate-unmatched')),
          'data-auto-animate-duration' => ((attr 'auto-animate-duration') || (option? 'auto-animate-duration')),
          'data-auto-animate-id' => (attr 'auto-animate-id'),
          'data-auto-animate-restart' => ((attr? 'auto-animate-restart') || (option? 'auto-animate-restart')),
        }) do
          inner = +''
          inner << %(<h2>#{section_title}</h2>) unless hide_title
          if parent_section_with_vertical_slides
            unless (_blocks = blocks - vertical_slides).empty?
              inner << %(<div class="slide-content">#{_blocks.map(&:convert).join}</div>)
            end
            inner << footnotes.call
          else
            unless (_content = content.chomp).empty?
              inner << %(<div class="slide-content">#{_content}</div>)
            end
            inner << footnotes.call
          end
          inner
        end
        clear_slide_footnotes
        buf
      end

      # RENDERING
      if parent_section_with_vertical_slides
        # render parent section of vertical slides set
        %(<section>#{section.call}#{vertical_slides.map(&:convert).join}</section>)
      elsif @level >= 3
        # dynamic tags which maps <hX> with level
        %(<h#{@level}>#{title}</h#{@level}>#{content.chomp})
      else
        # render standalone slides (or vertical slide subsection)
        section.call
      end
    end
  end

  def convert_sidebar(node, opts = {})
    render(node) do
      if (has_role? 'aside') or (has_role? 'speaker') or (has_role? 'notes')
        %(<aside class="notes">#{resolve_content}</aside>)
      else
        html_tag('div', { :id => @id, :class => ['sidebarblock', role, ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step'))] }.merge(data_attrs(@attributes))) do
          buf = %(<div class="content">)
          buf << %(<div class="title">#{title}</div>) if title?
          buf << content.to_s
          buf << %(</div>)
          buf
        end
      end
    end
  end

  def convert_stem(node, opts = {})
    render(node) do
      open, close = Asciidoctor::BLOCK_MATH_DELIMITERS[@style.to_sym]
      equation = content.strip
      if (@subs.nil? || @subs.empty?) && !(attr? 'subs')
        equation = sub_specialcharacters equation
      end
      unless (equation.start_with? open) && (equation.end_with? close)
        equation = %(#{open}#{equation}#{close})
      end
      html_tag('div', { :id => @id, :class => ['stemblock', role, ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step'))] }.merge(data_attrs(@attributes))) do
        buf = +''
        buf << %(<div class="title">#{title}</div>) if title?
        buf << %(<div class="content">#{equation}</div>)
        buf
      end
    end
  end

  def convert_stretch_nested_elements(node, opts = {})
    render(node) do
      stretch_nested_elements_script
    end
  end

  def convert_table(node, opts = {})
    render(node) do
      classes = ['tableblock', "frame-#{attr :frame, 'all'}", "grid-#{attr :grid, 'all'}", role, ('fragment' if (option? :step) || (attr? 'step'))]
      styles = [("width:#{attr :tablepcwidth}%" unless option? 'autowidth'), ("float:#{attr :float}" if attr? :float)].compact.join('; ')
      html_tag('table', { :id => @id, :class => classes, :style => styles }.merge(data_attrs(@attributes))) do
        buf = +''
        buf << %(<caption class="title">#{captioned_title}</caption>) if title?
        unless (attr :rowcount).zero?
          buf << '<colgroup>'
          if option? 'autowidth'
            @columns.each { buf << '<col>' }
          else
            @columns.each {|col| buf << %(<col style="width:#{col.attr :colpcwidth}%">) }
          end
          buf << '</colgroup>'
          [:head, :foot, :body].select {|tblsec| !@rows[tblsec].empty? }.each do |tblsec|
            buf << %(<t#{tblsec}>)
            @rows[tblsec].each do |row|
              buf << '<tr>'
              row.each do |cell|
                # store reference of content in advance to resolve attribute assignments in cells
                if tblsec == :head
                  cell_content = cell.text
                else
                  case cell.style
                  when :literal
                    cell_content = cell.text
                  else
                    cell_content = cell.content
                  end
                end
                buf << html_tag(tblsec == :head || cell.style == :header ? 'th' : 'td',
                    :class => ['tableblock', "halign-#{cell.attr :halign}", "valign-#{cell.attr :valign}"],
                    :colspan => cell.colspan, :rowspan => cell.rowspan,
                    :style => ((@document.attr? :cellbgcolor) ? %(background-color:#{@document.attr :cellbgcolor};) : nil)) do
                  if tblsec == :head
                    cell_content.to_s
                  else
                    case cell.style
                    when :asciidoc
                      %(<div>#{cell_content}</div>)
                    when :literal
                      %(<div class="literal"><pre>#{cell_content}</pre></div>)
                    when :header
                      cell_content.map {|text| %(<p class="tableblock header">#{text}</p>) }.join
                    else
                      cell_content.map {|text| %(<p class="tableblock">#{text}</p>) }.join
                    end
                  end
                end
              end
              buf << '</tr>'
            end
          end
        end
        buf
      end
    end
  end

  def convert_thematic_break(node, opts = {})
    render(node) do
      '<hr>'
    end
  end

  def convert_title_slide(node, opts = {})
    render(node) do
      bg_image = (attr? 'title-slide-background-image') ? (image_uri(attr 'title-slide-background-image')) : nil
      bg_video = (attr? 'title-slide-background-video') ? (media_uri(attr 'title-slide-background-video')) : nil
      html_tag('section', {
        :class => ['title', role],
        'data-state' => 'title',
        'data-transition' => (attr 'title-slide-transition'),
        'data-transition-speed' => (attr 'title-slide-transition-speed'),
        'data-background' => (attr 'title-slide-background'),
        'data-background-size' => (attr 'title-slide-background-size'),
        'data-background-image' => bg_image,
        'data-background-video' => bg_video,
        'data-background-video-loop' => (attr 'title-slide-background-video-loop'),
        'data-background-video-muted' => (attr 'title-slide-background-video-muted'),
        'data-background-opacity' => (attr 'title-slide-background-opacity'),
        'data-background-iframe' => (attr 'title-slide-background-iframe'),
        'data-background-color' => (attr 'title-slide-background-color'),
        'data-background-repeat' => (attr 'title-slide-background-repeat'),
        'data-background-position' => (attr 'title-slide-background-position'),
        'data-background-transition' => (attr 'title-slide-background-transition'),
      }) do
        buf = +''
        if (_title_obj = doctitle partition: true, use_fallback: true).subtitle?
          buf << %(<h1>#{slice_text _title_obj.title, (_slice = header.option? :slice)}</h1><h2>#{slice_text _title_obj.subtitle, _slice}</h2>)
        else
          buf << %(<h1>#{@header.title}</h1>)
        end
        preamble = @document.find_by context: :preamble
        unless preamble.nil? or preamble.length == 0
          buf << %(<div class="preamble">#{preamble.pop.content}</div>)
        end
        buf << generate_authors(@document).to_s
        buf
      end
    end
  end

  def convert_toc(node, opts = {})
    render(node) do
      html_tag('div', id: 'toc', class: (document.attr 'toc-class', 'toc')) do
        %(<div id="toctitle">#{document.attr 'toc-title'}</div>) +
          converter.convert(document, 'outline').to_s
      end
    end
  end

  def convert_ulist(node, opts = {})
    render(node) do
      if (checklist = (option? :checklist) ? 'checklist' : nil)
        if option? :interactive
          marker_checked = '<input type="checkbox" data-item-complete="1" checked>'
          marker_unchecked = '<input type="checkbox" data-item-complete="0">'
        elsif @document.attr? :icons, 'font'
          marker_checked = '<i class="icon-check"></i>'
          marker_unchecked = '<i class="icon-check-empty"></i>'
        else
          # could use &#9745 (checked ballot) and &#9744 (ballot) w/o font instead
          marker_checked = '<input type="checkbox" data-item-complete="1" checked disabled>'
          marker_unchecked = '<input type="checkbox" data-item-complete="0" disabled>'
        end
      end
      html_tag('div', { :id => @id, :class => ['ulist', checklist, @style, role] }.merge(data_attrs(@attributes))) do
        buf = +''
        buf << %(<div class="title">#{title}</div>) if title?
        buf << html_tag('ul', class: (checklist || @style)) do
          inner = +''
          items.each do |item|
            inner << html_tag('li', class: ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step'))) do
              li = '<p>'
              if checklist && (item.attr? :checkbox)
                li << %(#{(item.attr? :checked) ? marker_checked : marker_unchecked}#{item.text})
              else
                li << item.text.to_s
              end
              li << '</p>'
              li << item.content.to_s if item.blocks?
              li
            end
          end
          inner
        end
        buf
      end
    end
  end

  def convert_verse(node, opts = {})
    render(node) do
      html_tag('div', { :id => @id, :class => ['verseblock', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do
        buf = +''
        buf << %(<div class="title">#{title}</div>) if title?
        buf << %(<pre class="content">#{content}</pre>)
        attribution = (attr? :attribution) ? (attr :attribution) : nil
        citetitle = (attr? :citetitle) ? (attr :citetitle) : nil
        if attribution || citetitle
          buf << %(<div class="attribution">)
          buf << %(<cite>#{citetitle}</cite>) if citetitle
          if attribution
            buf << '<br>' if citetitle
            buf << %(&#8212; #{attribution})
          end
          buf << %(</div>)
        end
        buf
      end
    end
  end

  def convert_video(node, opts = {})
    render(node) do
      # in a slide-deck context we assume video should take as much place as possible
      # unless already specified
      no_stretch = ((attr? :width) || (attr? :height))
      width = (attr? :width) ? (attr :width) : "100%"
      height = (attr? :height) ? (attr :height) : "100%"
      # we apply revealjs stretch class to the videoblock take all the place we can
      html_tag('div', { :id => @id, :class => ['videoblock', @style, role, (no_stretch ? nil : 'stretch'), ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step'))] }.merge(data_attrs(@attributes))) do
        buf = +''
        buf << %(<div class="title">#{captioned_title}</div>) if title?
        case attr :poster
        when 'vimeo'
          unless (asset_uri_scheme = (attr :asset_uri_scheme, 'https')).empty?
            asset_uri_scheme = %(#{asset_uri_scheme}:)
          end
          start_anchor = (attr? :start) ? "#at=#{attr :start}" : nil
          delimiter = ['?']
          loop_param = (option? 'loop') ? %(#{delimiter.pop || '&amp;'}loop=1) : ''
          muted_param = (option? 'muted') ? %(#{delimiter.pop || '&amp;'}muted=1) : ''
          src = %(#{asset_uri_scheme}//player.vimeo.com/video/#{attr :target}#{loop_param}#{muted_param}#{start_anchor})
          # We need to delegate autoplay into the iframe starting with Chrome 62 (and other browsers too)
          # See https://developers.google.com/web/updates/2017/09/autoplay-policy-changes#iframe
          buf << html_tag('iframe', width: width, height: height, src: src, frameborder: 0,
            webkitAllowFullScreen: true, mozallowfullscreen: true, allowFullScreen: true,
            'data-autoplay' => (option? 'autoplay'),
            allow: ((option? 'autoplay') ? "autoplay" : nil))
        when 'youtube'
          unless (asset_uri_scheme = (attr :asset_uri_scheme, 'https')).empty?
            asset_uri_scheme = %(#{asset_uri_scheme}:)
          end
          params = ['rel=0']
          params << "start=#{attr :start}" if attr? :start
          params << "end=#{attr :end}" if attr? :end
          params << "loop=1" if option? 'loop'
          params << "mute=1" if option? 'muted'
          params << "controls=0" if option? 'nocontrols'
          src = %(#{asset_uri_scheme}//www.youtube.com/embed/#{attr :target}?#{params * '&amp;'})
          # We need to delegate autoplay into the iframe starting with Chrome 62 (and other browsers too)
          # See https://developers.google.com/web/updates/2017/09/autoplay-policy-changes#iframe
          buf << html_tag('iframe', width: width, height: height, src: src,
            frameborder: 0, allowfullscreen: !(option? 'nofullscreen'),
            'data-autoplay' => (option? 'autoplay'),
            allow: ((option? 'autoplay') ? "autoplay" : nil))
        else
          buf << html_tag('video', { src: media_uri(attr :target), width: width, height: height,
            poster: ((attr :poster) ? media_uri(attr :poster) : nil),
            'data-autoplay' => (option? 'autoplay'), controls: !(option? 'nocontrols'),
            loop: (option? 'loop') }, 'Your browser does not support the video tag.')
        end
        buf
      end
    end
  end

  def convert_document(node, opts = {})
    render(node) do
      slides_content = self.content
      slides = lambda do
        buf = +''
        unless noheader
          unless (header_docinfo = docinfo :header, '-revealjs.html').empty?
            buf << header_docinfo.to_s
          end
          buf << converter.convert(self, 'title_slide') if header?
        end
        buf << slides_content.to_s
        unless (footer_docinfo = docinfo :footer, '-revealjs.html').empty?
          buf << footer_docinfo.to_s
        end
        buf
      end

      if RUBY_ENGINE == 'opal' && JAVASCRIPT_PLATFORM == 'node'
        revealjsdir = (attr :revealjsdir, 'node_modules/reveal.js')
      else
        revealjsdir = (attr :revealjsdir, 'reveal.js')
      end
      unless (asset_uri_scheme = (attr 'asset-uri-scheme', 'https')).empty?
        asset_uri_scheme = %(#{asset_uri_scheme}:)
      end
      cdn_base = %(#{asset_uri_scheme}//cdnjs.cloudflare.com/ajax/libs)

      buf = +'<!DOCTYPE html><html'
      lang = (attr :lang, 'en' unless attr? :nolang)
      buf << %( lang="#{lang}") if lang
      buf << '><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, minimal-ui">'
      buf << %(<title>#{doctitle sanitize: true, use_fallback: true}</title>)

      [:description, :keywords, :author, :copyright].each do |key|
        buf << html_tag('meta', name: key.to_s, content: (attr key)) if attr? key
      end
      if attr? 'favicon'
        if (icon_href = attr 'favicon').empty?
          icon_href = 'favicon.ico'
          icon_type = 'image/x-icon'
        elsif (icon_ext = File.extname icon_href)
          icon_type = icon_ext == '.ico' ? 'image/x-icon' : %(image/#{icon_ext.slice 1, icon_ext.length})
        else
          icon_type = 'image/x-icon'
        end
        buf << %(<link rel="icon" type="#{icon_type}" href="#{icon_href}">)
      end
      linkcss = (attr? 'linkcss')
      buf << %(<link rel="stylesheet" href="#{revealjsdir}/dist/reset.css"><link rel="stylesheet" href="#{revealjsdir}/dist/reveal.css">)
      # Default theme required even when using custom theme
      buf << html_tag('link', rel: 'stylesheet', href: (attr :revealjs_customtheme, %(#{revealjsdir}/dist/theme/#{attr 'revealjs_theme', 'black'}.css)), id: 'theme')
      buf << %(<!--This CSS is generated by the Asciidoctor reveal.js converter to further integrate AsciiDoc's existing semantic with reveal.js-->)
      buf << %(<style type="text/css">#{Asciidoctor::Revealjs::Stylesheet::COMPATIBILITY}</style>)
      if attr? :icons, 'font'
        # iconfont-remote is implicitly set by Asciidoctor core. See https://github.com/asciidoctor/asciidoctor.org/issues/361
        if attr? 'iconfont-remote'
          if (iconfont_cdn = (attr 'iconfont-cdn'))
            buf << html_tag('link', rel: 'stylesheet', href: iconfont_cdn)
          else
            # default icon font is Font Awesome
            font_awesome_version = (attr 'font-awesome-version', '5.15.1')
            buf << html_tag('link', rel: 'stylesheet', href: %(#{cdn_base}/font-awesome/#{font_awesome_version}/css/all.min.css))
            buf << html_tag('link', rel: 'stylesheet', href: %(#{cdn_base}/font-awesome/#{font_awesome_version}/css/v4-shims.min.css))
          end
        else
          buf << html_tag('link', rel: 'stylesheet', href: (normalize_web_path %(#{attr 'iconfont-name', 'font-awesome'}.css), (attr 'stylesdir', ''), false))
        end
      end
      buf << generate_stem(cdn_base).to_s
      syntax_hl = self.syntax_highlighter
      if syntax_hl && (syntax_hl.docinfo? :head)
        buf << (syntax_hl.docinfo :head, self, cdn_base_url: cdn_base, linkcss: linkcss, self_closing_tag_slash: '/').to_s
      end
      if attr? :customcss
        buf << html_tag('link', rel: 'stylesheet', href: ((customcss = attr :customcss).empty? ? 'asciidoctor-revealjs.css' : customcss))
      end
      unless (_docinfo = docinfo :head, '-revealjs.html').empty?
        buf << _docinfo.to_s
      end
      buf << %(</head><body><div class="reveal"><div class="slides">)
      # Any section element inside of this container is displayed as a slide
      buf << slides.call
      buf << %(</div></div><script src="#{revealjsdir}/dist/reveal.js"></script>)
      # Supports easy AsciiDoc syntax for background color, then the reveal.js configuration
      buf << %(<script>) + <<~JS.chomp + %(</script>)
        Array.prototype.slice.call(document.querySelectorAll('.slides section')).forEach(function(slide) {
          if (slide.getAttribute('data-background-color')) return;
          // user needs to explicitly say he wants CSS color to override otherwise we might break custom css or theme (#226)
          if (!(slide.classList.contains('canvas') || slide.classList.contains('background'))) return;
          var bgColor = getComputedStyle(slide).backgroundColor;
          if (bgColor !== 'rgba(0, 0, 0, 0)' && bgColor !== 'transparent') {
            slide.setAttribute('data-background-color', bgColor);
            slide.style.backgroundColor = 'transparent';
          }
        });

        // More info about config & dependencies:
        // - https://github.com/hakimel/reveal.js#configuration
        // - https://github.com/hakimel/reveal.js#dependencies
        Reveal.initialize({
          // Display presentation control arrows
          controls: #{to_boolean(attr 'revealjs_controls', true)},
          // Help the user learn the controls by providing hints, for example by
          // bouncing the down arrow when they first encounter a vertical slide
          controlsTutorial: #{to_boolean(attr 'revealjs_controlstutorial', true)},
          // Determines where controls appear, "edges" or "bottom-right"
          controlsLayout: '#{attr 'revealjs_controlslayout', 'bottom-right'}',
          // Visibility rule for backwards navigation arrows; "faded", "hidden"
          // or "visible"
          controlsBackArrows: '#{attr 'revealjs_controlsbackarrows', 'faded'}',
          // Display a presentation progress bar
          progress: #{to_boolean(attr 'revealjs_progress', true)},
          // Display the page number of the current slide
          slideNumber: #{to_valid_slidenumber(attr 'revealjs_slidenumber', false)},
          // Control which views the slide number displays on
          showSlideNumber: '#{attr 'revealjs_showslidenumber', 'all'}',
          // Add the current slide number to the URL hash so that reloading the
          // page/copying the URL will return you to the same slide
          hash: #{to_boolean(attr 'revealjs_hash', false)},
          // Push each slide change to the browser history. Implies `hash: true`
          history: #{to_boolean(attr 'revealjs_history', false)},
          // Enable keyboard shortcuts for navigation
          keyboard: #{to_boolean(attr 'revealjs_keyboard', true)},
          // Enable the slide overview mode
          overview: #{to_boolean(attr 'revealjs_overview', true)},
          // Disables the default reveal.js slide layout so that you can use custom CSS layout
          disableLayout: #{to_boolean(attr 'revealjs_disablelayout', false)},
          // Vertical centering of slides
          center: #{to_boolean(attr 'revealjs_center', true)},
          // Enables touch navigation on devices with touch input
          touch: #{to_boolean(attr 'revealjs_touch', true)},
          // Loop the presentation
          loop: #{to_boolean(attr 'revealjs_loop', false)},
          // Change the presentation direction to be RTL
          rtl: #{to_boolean(attr 'revealjs_rtl', false)},
          // See https://github.com/hakimel/reveal.js/#navigation-mode
          navigationMode: '#{attr 'revealjs_navigationmode', 'default'}',
          // Randomizes the order of slides each time the presentation loads
          shuffle: #{to_boolean(attr 'revealjs_shuffle', false)},
          // Turns fragments on and off globally
          fragments: #{to_boolean(attr 'revealjs_fragments', true)},
          // Flags whether to include the current fragment in the URL,
          // so that reloading brings you to the same fragment position
          fragmentInURL: #{to_boolean(attr 'revealjs_fragmentinurl', false)},
          // Flags if the presentation is running in an embedded mode,
          // i.e. contained within a limited portion of the screen
          embedded: #{to_boolean(attr 'revealjs_embedded', false)},
          // Flags if we should show a help overlay when the questionmark
          // key is pressed
          help: #{to_boolean(attr 'revealjs_help', true)},
          // Flags if speaker notes should be visible to all viewers
          showNotes: #{to_boolean(attr 'revealjs_shownotes', false)},
          // Global override for autolaying embedded media (video/audio/iframe)
          // - null: Media will only autoplay if data-autoplay is present
          // - true: All media will autoplay, regardless of individual setting
          // - false: No media will autoplay, regardless of individual setting
          autoPlayMedia: #{attr 'revealjs_autoplaymedia', 'null'},
          // Global override for preloading lazy-loaded iframes
          // - null: Iframes with data-src AND data-preload will be loaded when within
          //   the viewDistance, iframes with only data-src will be loaded when visible
          // - true: All iframes with data-src will be loaded when within the viewDistance
          // - false: All iframes with data-src will be loaded only when visible
          preloadIframes: #{attr 'revealjs_preloadiframes', 'null'},
          // Number of milliseconds between automatically proceeding to the
          // next slide, disabled when set to 0, this value can be overwritten
          // by using a data-autoslide attribute on your slides
          autoSlide: #{attr 'revealjs_autoslide', 0},
          // Stop auto-sliding after user input
          autoSlideStoppable: #{to_boolean(attr 'revealjs_autoslidestoppable', true)},
          // Use this method for navigation when auto-sliding
          autoSlideMethod: #{attr 'revealjs_autoslidemethod', 'Reveal.navigateNext'},
          // Specify the average time in seconds that you think you will spend
          // presenting each slide. This is used to show a pacing timer in the
          // speaker view
          defaultTiming: #{attr 'revealjs_defaulttiming', 120},
          // Specify the total time in seconds that is available to
          // present.  If this is set to a nonzero value, the pacing
          // timer will work out the time available for each slide,
          // instead of using the defaultTiming value
          totalTime: #{attr 'revealjs_totaltime', 0},
          // Specify the minimum amount of time you want to allot to
          // each slide, if using the totalTime calculation method.  If
          // the automated time allocation causes slide pacing to fall
          // below this threshold, then you will see an alert in the
          // speaker notes window
          minimumTimePerSlide: #{attr 'revealjs_minimumtimeperslide', 0},
          // Enable slide navigation via mouse wheel
          mouseWheel: #{to_boolean(attr 'revealjs_mousewheel', false)},
          // Hide cursor if inactive
          hideInactiveCursor: #{to_boolean(attr 'revealjs_hideinactivecursor', true)},
          // Time before the cursor is hidden (in ms)
          hideCursorTime: #{attr 'revealjs_hidecursortime', 5000},
          // Hides the address bar on mobile devices
          hideAddressBar: #{to_boolean(attr 'revealjs_hideaddressbar', true)},
          // Opens links in an iframe preview overlay
          // Add `data-preview-link` and `data-preview-link="false"` to customise each link
          // individually
          previewLinks: #{to_boolean(attr 'revealjs_previewlinks', false)},
          // Transition style (e.g., none, fade, slide, convex, concave, zoom)
          transition: '#{attr 'revealjs_transition', 'slide'}',
          // Transition speed (e.g., default, fast, slow)
          transitionSpeed: '#{attr 'revealjs_transitionspeed', 'default'}',
          // Transition style for full page slide backgrounds (e.g., none, fade, slide, convex, concave, zoom)
          backgroundTransition: '#{attr 'revealjs_backgroundtransition', 'fade'}',
          // Number of slides away from the current that are visible
          viewDistance: #{attr 'revealjs_viewdistance', 3},
          // Number of slides away from the current that are visible on mobile
          // devices. It is advisable to set this to a lower number than
          // viewDistance in order to save resources.
          mobileViewDistance: #{attr 'revealjs_mobileviewdistance', 3},
          // Parallax background image (e.g., "'https://s3.amazonaws.com/hakim-static/reveal-js/reveal-parallax-1.jpg'")
          parallaxBackgroundImage: '#{attr 'revealjs_parallaxbackgroundimage', ''}',
          // Parallax background size in CSS syntax (e.g., "2100px 900px")
          parallaxBackgroundSize: '#{attr 'revealjs_parallaxbackgroundsize', ''}',
          // Number of pixels to move the parallax background per slide
          // - Calculated automatically unless specified
          // - Set to 0 to disable movement along an axis
          parallaxBackgroundHorizontal: #{attr 'revealjs_parallaxbackgroundhorizontal', 'null'},
          parallaxBackgroundVertical: #{attr 'revealjs_parallaxbackgroundvertical', 'null'},
          // The display mode that will be used to show slides
          display: '#{attr 'revealjs_display', 'block'}',

          // The "normal" size of the presentation, aspect ratio will be preserved
          // when the presentation is scaled to fit different resolutions. Can be
          // specified using percentage units.
          width: #{attr 'revealjs_width', 960},
          height: #{attr 'revealjs_height', 700},

          // Factor of the display size that should remain empty around the content
          margin: #{attr 'revealjs_margin', 0.1},

          // Bounds for smallest/largest possible scale to apply to content
          minScale: #{attr 'revealjs_minscale', 0.2},
          maxScale: #{attr 'revealjs_maxscale', 1.5},

          // PDF Export Options
          // Put each fragment on a separate page
          pdfSeparateFragments: #{to_boolean(attr 'revealjs_pdfseparatefragments', true)},
          // For slides that do not fit on a page, max number of pages
          pdfMaxPagesPerSlide: #{attr 'revealjs_pdfmaxpagesperslide', 1},

          // Optional libraries used to extend on reveal.js
          dependencies: [
              #{revealjs_dependencies(document, self, revealjsdir)}
          ],
        });
      JS
      # Workaround the "Only direct descendants of a slide section can be stretched" limitation in reveal.js
      # https://github.com/hakimel/reveal.js/issues/2584
      buf << stretch_nested_elements_script

      if syntax_hl && (syntax_hl.docinfo? :footer)
        buf << (syntax_hl.docinfo :footer, self, cdn_base_url: cdn_base, linkcss: linkcss, self_closing_tag_slash: '/').to_s
      end
      unless (docinfo_content = (docinfo :footer, '.html')).empty?
        buf << docinfo_content.to_s
      end
      buf << '</body></html>'
      buf
    end
  end
end
