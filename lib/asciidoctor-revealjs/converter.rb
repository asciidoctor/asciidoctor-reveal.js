# This file has been generated!

module Asciidoctor; module Revealjs; end end
class Asciidoctor::Revealjs::Converter < ::Asciidoctor::Converter::Base

  #------------------------------ Begin of Helpers ------------------------------#

  unless RUBY_ENGINE == 'opal'
    # This helper file borrows from the Bespoke converter
    # https://github.com/asciidoctor/asciidoctor-bespoke
    require 'asciidoctor'
  end

  require 'json'

  # This module gets mixed in to every node (the context of the template) at the
  # time the node is being converted. The properties and methods in this module
  # effectively become direct members of the template.
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
    # @yield The block of Slim/HTML code within the tag (optional).
    # @return [String] a rendered HTML element.
    #
    def html_tag(name, attributes = {}, content = nil)
      attrs = attributes.inject([]) do |attrs, (k, v)|
        next attrs unless v && (v == true || !v.nil_or_empty?)
        v = v.compact.join(' ') if v.is_a? Array
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

    # Capture nested template content and register it with the specified key, to
    # be executed at a later time.
    #
    # This method must be invoked using the control code directive (i.e., -). By
    # using a control code directive, the block is set up to append the result
    # directly to the output buffer. (Integrations often hide the distinction
    # between a control code directive and an output directive in this context).
    #
    # key   - The Symbol under which to save the template block.
    # opts  - A Hash of options to control processing (default: {}):
    #         * :append  - A Boolean that indicates whether to append this block
    #                      to others registered with this key (default: false).
    #         * :content - String content to be used if template content is not
    #                      provided (optional).
    # block - The template content (in Slim template syntax).
    #
    # Examples
    #
    #   - content_for :body
    #     p content
    #   - content_for :body, append: true
    #     p more content
    #
    # Returns nothing.
    def content_for key, opts = {}, &block
      @content = {} unless defined? @content
      (opts[:append] ? (@content[key] ||= []) : (@content[key] = [])) << (block_given? ? block : lambda { opts[:content] })
      nil
    end

    # Checks whether deferred template content has been registered for the specified key.
    #
    # key - The Symbol under which to look for saved template blocks.
    #
    # Returns a Boolean indicating whether content has been registered for this key.
    def content_for? key
      (defined? @content) && (@content.key? key)
    end

    # Evaluates the deferred template content registered with the specified key.
    #
    # When the corresponding content_for method is invoked using a control code
    # directive, the block is set up to append the result to the output buffer
    # directly.
    #
    # key  - The Symbol under which to look for template blocks to yield.
    # opts - A Hash of options to control processing (default: {}):
    #        * :drain - A Boolean indicating whether to drain the key of blocks
    #                   after calling them (default: true).
    #
    # Examples
    #
    #   - yield_content :body
    #
    # Returns nothing (assuming the content has been captured in the context of control code).
    def yield_content key, opts = {}
      if (defined? @content) && (blks = (opts.fetch :drain, true) ? (@content.delete key) : @content[key])
        blks.map {|b| b.call }.join
      end
      nil
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
  end

  # More custom functions can be added in another namespace if required
  #module Helpers
  #end


  # Make Helpers' constants accessible from transform methods.
  Helpers.constants.each do |const|
    const_set(const, Helpers.const_get(const))
  end

  #------------------------------- End of Helpers -------------------------------#


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

  #----------------- Begin of generated transformation methods -----------------#


  def convert_admonition(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; if (has_role? 'aside') or (has_role? 'speaker') or (has_role? 'notes'); 
      ; _buf << ("<aside class=\"notes\">"); _buf << (resolve_content); 
      ; _buf << ("</aside>"); 
      ; else; 
      ; _slim_controls1 = html_tag('div', { :id => @id, :class => ['admonitionblock', (attr :name), role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; _slim_controls2 << ("<table><tr><td class=\"icon\">"); 
      ; 
      ; if @document.attr? :icons, 'font'; 
      ; icon_mapping = Hash['caution', 'fire', 'important', 'exclamation-circle', 'note', 'info-circle', 'tip', 'lightbulb-o', 'warning', 'warning']; 
      ; _slim_controls2 << ("<i"); _temple_html_attributeremover1 = []; _slim_codeattributes1 = %(fa fa-#{icon_mapping[attr :name]}); if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes1.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes1); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover1); _slim_controls2 << ("\""); end; _slim_codeattributes2 = (attr :textlabel || @caption); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls2 << (" title"); else; _slim_controls2 << (" title=\""); _slim_controls2 << (_slim_codeattributes2); _slim_controls2 << ("\""); end; end; _slim_controls2 << ("></i>"); 
      ; elsif @document.attr? :icons; 
      ; _slim_controls2 << ("<img"); _slim_codeattributes3 = icon_uri(attr :name); if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" src"); else; _slim_controls2 << (" src=\""); _slim_controls2 << (_slim_codeattributes3); _slim_controls2 << ("\""); end; end; _slim_codeattributes4 = @caption; if _slim_codeattributes4; if _slim_codeattributes4 == true; _slim_controls2 << (" alt"); else; _slim_controls2 << (" alt=\""); _slim_controls2 << (_slim_codeattributes4); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">"); 
      ; else; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << ((attr :textlabel) || @caption); 
      ; _slim_controls2 << ("</div>"); end; _slim_controls2 << ("</td><td class=\"content\">"); 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (title); 
      ; _slim_controls2 << ("</div>"); end; _slim_controls2 << (content); 
      ; _slim_controls2 << ("</td></tr></table>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); end; _buf = _buf.join("")
    end
  end

  def convert_audio(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _slim_controls1 = html_tag('div', { :id => @id, :class => ['audioblock', @style, role] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (captioned_title); 
      ; _slim_controls2 << ("</div>"); end; _slim_controls2 << ("<div class=\"content\"><audio"); 
      ; _slim_codeattributes1 = media_uri(attr :target); if _slim_codeattributes1; if _slim_codeattributes1 == true; _slim_controls2 << (" src"); else; _slim_controls2 << (" src=\""); _slim_controls2 << (_slim_codeattributes1); _slim_controls2 << ("\""); end; end; _slim_codeattributes2 = (option? 'autoplay'); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls2 << (" autoplay"); else; _slim_controls2 << (" autoplay=\""); _slim_controls2 << (_slim_codeattributes2); _slim_controls2 << ("\""); end; end; _slim_codeattributes3 = !(option? 'nocontrols'); if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" controls"); else; _slim_controls2 << (" controls=\""); _slim_controls2 << (_slim_codeattributes3); _slim_controls2 << ("\""); end; end; _slim_codeattributes4 = (option? 'loop'); if _slim_codeattributes4; if _slim_codeattributes4 == true; _slim_controls2 << (" loop"); else; _slim_controls2 << (" loop=\""); _slim_controls2 << (_slim_codeattributes4); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">Your browser does not support the audio tag.</audio></div>"); 
      ; 
      ; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def convert_colist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _slim_controls1 = html_tag('div', { :id => @id, :class => ['colist', @style, role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (title); 
      ; _slim_controls2 << ("</div>"); end; if @document.attr? :icons; 
      ; font_icons = @document.attr? :icons, 'font'; 
      ; _slim_controls2 << ("<table>"); 
      ; items.each_with_index do |item, i|; 
      ; num = i + 1; 
      ; _slim_controls2 << ("<tr><td>"); 
      ; 
      ; if font_icons; 
      ; _slim_controls2 << ("<i class=\"conum\""); _slim_codeattributes1 = num; if _slim_codeattributes1; if _slim_codeattributes1 == true; _slim_controls2 << (" data-value"); else; _slim_controls2 << (" data-value=\""); _slim_controls2 << (_slim_codeattributes1); _slim_controls2 << ("\""); end; end; _slim_controls2 << ("></i><b>"); 
      ; _slim_controls2 << (num); 
      ; _slim_controls2 << ("</b>"); else; 
      ; _slim_controls2 << ("<img"); _slim_codeattributes2 = icon_uri("callouts/#{num}"); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls2 << (" src"); else; _slim_controls2 << (" src=\""); _slim_controls2 << (_slim_codeattributes2); _slim_controls2 << ("\""); end; end; _slim_codeattributes3 = num; if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" alt"); else; _slim_controls2 << (" alt=\""); _slim_controls2 << (_slim_codeattributes3); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">"); 
      ; end; _slim_controls2 << ("</td><td>"); _slim_controls2 << (item.text); 
      ; _slim_controls2 << ("</td></tr>"); end; _slim_controls2 << ("</table>"); else; 
      ; _slim_controls2 << ("<ol>"); 
      ; items.each do |item|; 
      ; _slim_controls2 << ("<li><p>"); _slim_controls2 << (item.text); 
      ; _slim_controls2 << ("</p></li>"); end; _slim_controls2 << ("</ol>"); end; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def convert_dlist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; case @style; 
      ; when 'qanda'; 
      ; _slim_controls1 = html_tag('div', { :id => @id, :class => ['qlist', @style, role] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (title); 
      ; _slim_controls2 << ("</div>"); end; _slim_controls2 << ("<ol>"); 
      ; items.each do |questions, answer|; 
      ; _slim_controls2 << ("<li>"); 
      ; [*questions].each do |question|; 
      ; _slim_controls2 << ("<p><em>"); _slim_controls2 << (question.text); 
      ; _slim_controls2 << ("</em></p>"); end; unless answer.nil?; 
      ; if answer.text?; 
      ; _slim_controls2 << ("<p>"); _slim_controls2 << (answer.text); 
      ; _slim_controls2 << ("</p>"); end; if answer.blocks?; 
      ; _slim_controls2 << (answer.content); 
      ; end; end; _slim_controls2 << ("</li>"); end; _slim_controls2 << ("</ol>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); when 'horizontal'; 
      ; _slim_controls3 = html_tag('div', { :id => @id, :class => ['hdlist', role] }.merge(data_attrs(@attributes))) do; _slim_controls4 = []; 
      ; if title?; 
      ; _slim_controls4 << ("<div class=\"title\">"); _slim_controls4 << (title); 
      ; _slim_controls4 << ("</div>"); end; _slim_controls4 << ("<table>"); 
      ; if (attr? :labelwidth) || (attr? :itemwidth); 
      ; _slim_controls4 << ("<colgroup><col"); 
      ; _slim_codeattributes1 = ((attr? :labelwidth) ? %(width:#{(attr :labelwidth).chomp '%'}%;) : nil); if _slim_codeattributes1; if _slim_codeattributes1 == true; _slim_controls4 << (" style"); else; _slim_controls4 << (" style=\""); _slim_controls4 << (_slim_codeattributes1); _slim_controls4 << ("\""); end; end; _slim_controls4 << ("><col"); 
      ; _slim_codeattributes2 = ((attr? :itemwidth) ? %(width:#{(attr :itemwidth).chomp '%'}%;) : nil); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls4 << (" style"); else; _slim_controls4 << (" style=\""); _slim_controls4 << (_slim_codeattributes2); _slim_controls4 << ("\""); end; end; _slim_controls4 << ("></colgroup>"); 
      ; end; items.each do |terms, dd|; 
      ; _slim_controls4 << ("<tr><td"); 
      ; _temple_html_attributeremover1 = []; _slim_codeattributes3 = ['hdlist1',('strong' if option? 'strong')]; if Array === _slim_codeattributes3; _slim_codeattributes3 = _slim_codeattributes3.flatten; _slim_codeattributes3.map!(&:to_s); _slim_codeattributes3.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes3.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes3); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _slim_controls4 << (" class=\""); _slim_controls4 << (_temple_html_attributeremover1); _slim_controls4 << ("\""); end; _slim_controls4 << (">"); 
      ; terms = [*terms]; 
      ; last_term = terms.last; 
      ; terms.each do |dt|; 
      ; _slim_controls4 << (dt.text); 
      ; if dt != last_term; 
      ; _slim_controls4 << ("<br>"); 
      ; end; end; _slim_controls4 << ("</td><td class=\"hdlist2\">"); 
      ; unless dd.nil?; 
      ; if dd.text?; 
      ; _slim_controls4 << ("<p>"); _slim_controls4 << (dd.text); 
      ; _slim_controls4 << ("</p>"); end; if dd.blocks?; 
      ; _slim_controls4 << (dd.content); 
      ; end; end; _slim_controls4 << ("</td></tr>"); end; _slim_controls4 << ("</table>"); _slim_controls4 = _slim_controls4.join(""); end; _buf << (_slim_controls3); else; 
      ; _slim_controls5 = html_tag('div', { :id => @id, :class => ['dlist', @style, role] }.merge(data_attrs(@attributes))) do; _slim_controls6 = []; 
      ; if title?; 
      ; _slim_controls6 << ("<div class=\"title\">"); _slim_controls6 << (title); 
      ; _slim_controls6 << ("</div>"); end; _slim_controls6 << ("<dl>"); 
      ; items.each do |terms, dd|; 
      ; [*terms].each do |dt|; 
      ; _slim_controls6 << ("<dt"); _temple_html_attributeremover2 = []; _slim_codeattributes4 = ('hdlist1' unless @style); if Array === _slim_codeattributes4; _slim_codeattributes4 = _slim_codeattributes4.flatten; _slim_codeattributes4.map!(&:to_s); _slim_codeattributes4.reject!(&:empty?); _temple_html_attributeremover2 << (_slim_codeattributes4.join(" ")); else; _temple_html_attributeremover2 << (_slim_codeattributes4); end; _temple_html_attributeremover2 = _temple_html_attributeremover2.join(""); if !_temple_html_attributeremover2.empty?; _slim_controls6 << (" class=\""); _slim_controls6 << (_temple_html_attributeremover2); _slim_controls6 << ("\""); end; _slim_controls6 << (">"); _slim_controls6 << (dt.text); 
      ; _slim_controls6 << ("</dt>"); end; unless dd.nil?; 
      ; _slim_controls6 << ("<dd>"); 
      ; if dd.text?; 
      ; _slim_controls6 << ("<p>"); _slim_controls6 << (dd.text); 
      ; _slim_controls6 << ("</p>"); end; if dd.blocks?; 
      ; _slim_controls6 << (dd.content); 
      ; end; _slim_controls6 << ("</dd>"); end; end; _slim_controls6 << ("</dl>"); _slim_controls6 = _slim_controls6.join(""); end; _buf << (_slim_controls5); end; _buf = _buf.join("")
    end
  end

  def convert_document(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; slides_content = self.content; 
      ; content_for :slides do; 
      ; unless noheader; 
      ; unless (header_docinfo = docinfo :header, '-revealjs.html').empty?; 
      ; _buf << (header_docinfo); 
      ; end; if header?; 
      ; bg_image = (attr? 'title-slide-background-image') ? (image_uri(attr 'title-slide-background-image')) : nil; 
      ; bg_video = (attr? 'title-slide-background-video') ? (media_uri(attr 'title-slide-background-video')) : nil; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ("<section"); _temple_html_attributeremover1 = []; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "title"; _temple_html_attributemerger1[1] = []; _slim_codeattributes1 = role; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << (_slim_codeattributes1.join(" ")); else; _temple_html_attributemerger1[1] << (_slim_codeattributes1); end; _temple_html_attributemerger1[1] = _temple_html_attributemerger1[1].join(""); _temple_html_attributeremover1 << (_temple_html_attributemerger1.reject(&:empty?).join(" ")); _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _buf << (" data-state=\"title\""); _slim_codeattributes2 = (attr 'title-slide-transition'); if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" data-transition"); else; _buf << (" data-transition=\""); _buf << (_slim_codeattributes2); _buf << ("\""); end; end; _slim_codeattributes3 = (attr 'title-slide-transition-speed'); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" data-transition-speed"); else; _buf << (" data-transition-speed=\""); _buf << (_slim_codeattributes3); _buf << ("\""); end; end; _slim_codeattributes4 = (attr 'title-slide-background'); if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" data-background"); else; _buf << (" data-background=\""); _buf << (_slim_codeattributes4); _buf << ("\""); end; end; _slim_codeattributes5 = (attr 'title-slide-background-size'); if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" data-background-size"); else; _buf << (" data-background-size=\""); _buf << (_slim_codeattributes5); _buf << ("\""); end; end; _slim_codeattributes6 = bg_image; if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" data-background-image"); else; _buf << (" data-background-image=\""); _buf << (_slim_codeattributes6); _buf << ("\""); end; end; _slim_codeattributes7 = bg_video; if _slim_codeattributes7; if _slim_codeattributes7 == true; _buf << (" data-background-video"); else; _buf << (" data-background-video=\""); _buf << (_slim_codeattributes7); _buf << ("\""); end; end; _slim_codeattributes8 = (attr 'title-slide-background-video-loop'); if _slim_codeattributes8; if _slim_codeattributes8 == true; _buf << (" data-background-video-loop"); else; _buf << (" data-background-video-loop=\""); _buf << (_slim_codeattributes8); _buf << ("\""); end; end; _slim_codeattributes9 = (attr 'title-slide-background-video-muted'); if _slim_codeattributes9; if _slim_codeattributes9 == true; _buf << (" data-background-video-muted"); else; _buf << (" data-background-video-muted=\""); _buf << (_slim_codeattributes9); _buf << ("\""); end; end; _slim_codeattributes10 = (attr 'title-slide-background-opacity'); if _slim_codeattributes10; if _slim_codeattributes10 == true; _buf << (" data-background-opacity"); else; _buf << (" data-background-opacity=\""); _buf << (_slim_codeattributes10); _buf << ("\""); end; end; _slim_codeattributes11 = (attr 'title-slide-background-iframe'); if _slim_codeattributes11; if _slim_codeattributes11 == true; _buf << (" data-background-iframe"); else; _buf << (" data-background-iframe=\""); _buf << (_slim_codeattributes11); _buf << ("\""); end; end; _slim_codeattributes12 = (attr 'title-slide-background-color'); if _slim_codeattributes12; if _slim_codeattributes12 == true; _buf << (" data-background-color"); else; _buf << (" data-background-color=\""); _buf << (_slim_codeattributes12); _buf << ("\""); end; end; _slim_codeattributes13 = (attr 'title-slide-background-repeat'); if _slim_codeattributes13; if _slim_codeattributes13 == true; _buf << (" data-background-repeat"); else; _buf << (" data-background-repeat=\""); _buf << (_slim_codeattributes13); _buf << ("\""); end; end; _slim_codeattributes14 = (attr 'title-slide-background-position'); if _slim_codeattributes14; if _slim_codeattributes14 == true; _buf << (" data-background-position"); else; _buf << (" data-background-position=\""); _buf << (_slim_codeattributes14); _buf << ("\""); end; end; _slim_codeattributes15 = (attr 'title-slide-background-transition'); if _slim_codeattributes15; if _slim_codeattributes15 == true; _buf << (" data-background-transition"); else; _buf << (" data-background-transition=\""); _buf << (_slim_codeattributes15); _buf << ("\""); end; end; _buf << (">"); 
      ; if (_title_obj = doctitle partition: true, use_fallback: true).subtitle?; 
      ; _buf << ("<h1>"); _buf << (slice_text _title_obj.title, (_slice = header.option? :slice)); 
      ; _buf << ("</h1><h2>"); _buf << (slice_text _title_obj.subtitle, _slice); 
      ; _buf << ("</h2>"); else; 
      ; _buf << ("<h1>"); _buf << (@header.title); 
      ; _buf << ("</h1>"); end; preamble = @document.find_by context: :preamble; 
      ; unless preamble.nil? or preamble.length == 0; 
      ; _buf << ("<div class=\"preamble\">"); _buf << (preamble.pop.content); 
      ; _buf << ("</div>"); end; _buf << (generate_authors(@document)); 
      ; _buf << ("</section>"); 
      ; end; end; _buf << (slides_content); 
      ; unless (footer_docinfo = docinfo :footer, '-revealjs.html').empty?; 
      ; _buf << (footer_docinfo); 
      ; 
      ; end; end; _buf << ("<!DOCTYPE html><html"); 
      ; _slim_codeattributes16 = (attr :lang, 'en' unless attr? :nolang); if _slim_codeattributes16; if _slim_codeattributes16 == true; _buf << (" lang"); else; _buf << (" lang=\""); _buf << (_slim_codeattributes16); _buf << ("\""); end; end; _buf << ("><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, minimal-ui\"><title>"); 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ((doctitle sanitize: true, use_fallback: true)); 
      ; 
      ; _buf << ("</title>"); if RUBY_ENGINE == 'opal' && JAVASCRIPT_PLATFORM == 'node'; 
      ; revealjsdir = (attr :revealjsdir, 'node_modules/reveal.js'); 
      ; else; 
      ; revealjsdir = (attr :revealjsdir, 'reveal.js'); 
      ; end; unless (asset_uri_scheme = (attr 'asset-uri-scheme', 'https')).empty?; 
      ; asset_uri_scheme = %(#{asset_uri_scheme}:); 
      ; end; cdn_base = %(#{asset_uri_scheme}//cdnjs.cloudflare.com/ajax/libs); 
      ; [:description, :keywords, :author, :copyright].each do |key|; 
      ; if attr? key; 
      ; _buf << ("<meta"); _slim_codeattributes17 = key; if _slim_codeattributes17; if _slim_codeattributes17 == true; _buf << (" name"); else; _buf << (" name=\""); _buf << (_slim_codeattributes17); _buf << ("\""); end; end; _slim_codeattributes18 = (attr key); if _slim_codeattributes18; if _slim_codeattributes18 == true; _buf << (" content"); else; _buf << (" content=\""); _buf << (_slim_codeattributes18); _buf << ("\""); end; end; _buf << (">"); 
      ; end; end; if attr? 'favicon'; 
      ; if (icon_href = attr 'favicon').empty?; 
      ; icon_href = 'favicon.ico'; 
      ; icon_type = 'image/x-icon'; 
      ; elsif (icon_ext = File.extname icon_href); 
      ; icon_type = icon_ext == '.ico' ? 'image/x-icon' : %(image/#{icon_ext.slice 1, icon_ext.length}); 
      ; else; 
      ; icon_type = 'image/x-icon'; 
      ; end; _buf << ("<link rel=\"icon\" type=\""); _buf << (icon_type); _buf << ("\" href=\""); _buf << (icon_href); _buf << ("\">"); 
      ; end; linkcss = (attr? 'linkcss'); 
      ; _buf << ("<link rel=\"stylesheet\" href=\""); _buf << (revealjsdir); _buf << ("/dist/reset.css\"><link rel=\"stylesheet\" href=\""); 
      ; _buf << (revealjsdir); _buf << ("/dist/reveal.css\"><link rel=\"stylesheet\""); 
      ; 
      ; 
      ; _slim_codeattributes19 = (attr :revealjs_customtheme, %(#{revealjsdir}/dist/theme/#{attr 'revealjs_theme', 'black'}.css)); if _slim_codeattributes19; if _slim_codeattributes19 == true; _buf << (" href"); else; _buf << (" href=\""); _buf << (_slim_codeattributes19); _buf << ("\""); end; end; _buf << (" id=\"theme\"><!--This CSS is generated by the Asciidoctor reveal.js converter to further integrate AsciiDoc's existing semantic with reveal.js--><style type=\"text/css\">.reveal div.right {\n  float: right\n}\n\n/* source blocks */\n.reveal .listingblock.stretch > .content {\n  height: 100%\n}\n\n.reveal .listingblock.stretch > .content > pre {\n  height: 100%\n}\n\n.reveal .listingblock.stretch > .content > pre > code {\n  height: 100%;\n  max-height: 100%\n}\n\n/* auto-animate feature */\n/* hide the scrollbar when auto-animating source blocks */\n.reveal pre[data-auto-animate-target] {\n  overflow: hidden;\n}\n\n.reveal pre[data-auto-animate-target] code {\n  overflow: hidden;\n}\n\n/* add a min width to avoid horizontal shift on line numbers */\ncode.hljs .hljs-ln-line.hljs-ln-n {\n  min-width: 1.25em;\n}\n\n/* tables */\ntable {\n  border-collapse: collapse;\n  border-spacing: 0\n}\n\ntable {\n  margin-bottom: 1.25em;\n  border: solid 1px #dedede\n}\n\ntable thead tr th, table thead tr td, table tfoot tr th, table tfoot tr td {\n  padding: .5em .625em .625em;\n  font-size: inherit;\n  text-align: left\n}\n\ntable tr th, table tr td {\n  padding: .5625em .625em;\n  font-size: inherit\n}\n\ntable thead tr th, table tfoot tr th, table tbody tr td, table tr td, table tfoot tr td {\n  display: table-cell;\n  line-height: 1.6\n}\n\ntd.tableblock > .content {\n  margin-bottom: 1.25em\n}\n\ntd.tableblock > .content > :last-child {\n  margin-bottom: -1.25em\n}\n\ntable.tableblock, th.tableblock, td.tableblock {\n  border: 0 solid #dedede\n}\n\ntable.grid-all > thead > tr > .tableblock, table.grid-all > tbody > tr > .tableblock {\n  border-width: 0 1px 1px 0\n}\n\ntable.grid-all > tfoot > tr > .tableblock {\n  border-width: 1px 1px 0 0\n}\n\ntable.grid-cols > * > tr > .tableblock {\n  border-width: 0 1px 0 0\n}\n\ntable.grid-rows > thead > tr > .tableblock, table.grid-rows > tbody > tr > .tableblock {\n  border-width: 0 0 1px\n}\n\ntable.grid-rows > tfoot > tr > .tableblock {\n  border-width: 1px 0 0\n}\n\ntable.grid-all > * > tr > .tableblock:last-child, table.grid-cols > * > tr > .tableblock:last-child {\n  border-right-width: 0\n}\n\ntable.grid-all > tbody > tr:last-child > .tableblock, table.grid-all > thead:last-child > tr > .tableblock, table.grid-rows > tbody > tr:last-child > .tableblock, table.grid-rows > thead:last-child > tr > .tableblock {\n  border-bottom-width: 0\n}\n\ntable.frame-all {\n  border-width: 1px\n}\n\ntable.frame-sides {\n  border-width: 0 1px\n}\n\ntable.frame-topbot, table.frame-ends {\n  border-width: 1px 0\n}\n\n.reveal table th.halign-left, .reveal table td.halign-left {\n  text-align: left\n}\n\n.reveal table th.halign-right, .reveal table td.halign-right {\n  text-align: right\n}\n\n.reveal table th.halign-center, .reveal table td.halign-center {\n  text-align: center\n}\n\n.reveal table th.valign-top, .reveal table td.valign-top {\n  vertical-align: top\n}\n\n.reveal table th.valign-bottom, .reveal table td.valign-bottom {\n  vertical-align: bottom\n}\n\n.reveal table th.valign-middle, .reveal table td.valign-middle {\n  vertical-align: middle\n}\n\ntable thead th, table tfoot th {\n  font-weight: bold\n}\n\ntbody tr th {\n  display: table-cell;\n  line-height: 1.6\n}\n\ntbody tr th, tbody tr th p, tfoot tr th, tfoot tr th p {\n  font-weight: bold\n}\n\nthead {\n  display: table-header-group\n}\n\n.reveal table.grid-none th, .reveal table.grid-none td {\n  border-bottom: 0 !important\n}\n\n/* kbd macro */\nkbd {\n  font-family: \"Droid Sans Mono\", \"DejaVu Sans Mono\", monospace;\n  display: inline-block;\n  color: rgba(0, 0, 0, .8);\n  font-size: .65em;\n  line-height: 1.45;\n  background: #f7f7f7;\n  border: 1px solid #ccc;\n  -webkit-border-radius: 3px;\n  border-radius: 3px;\n  -webkit-box-shadow: 0 1px 0 rgba(0, 0, 0, .2), 0 0 0 .1em white inset;\n  box-shadow: 0 1px 0 rgba(0, 0, 0, .2), 0 0 0 .1em #fff inset;\n  margin: 0 .15em;\n  padding: .2em .5em;\n  vertical-align: middle;\n  position: relative;\n  top: -.1em;\n  white-space: nowrap\n}\n\n.keyseq kbd:first-child {\n  margin-left: 0\n}\n\n.keyseq kbd:last-child {\n  margin-right: 0\n}\n\n/* callouts */\n.conum[data-value] {\n  display: inline-block;\n  color: #fff !important;\n  background: rgba(0, 0, 0, .8);\n  -webkit-border-radius: 50%;\n  border-radius: 50%;\n  text-align: center;\n  font-size: .75em;\n  width: 1.67em;\n  height: 1.67em;\n  line-height: 1.67em;\n  font-family: \"Open Sans\", \"DejaVu Sans\", sans-serif;\n  font-style: normal;\n  font-weight: bold\n}\n\n.conum[data-value] * {\n  color: #fff !important\n}\n\n.conum[data-value] + b {\n  display: none\n}\n\n.conum[data-value]:after {\n  content: attr(data-value)\n}\n\npre .conum[data-value] {\n  position: relative;\n  top: -.125em\n}\n\nb.conum * {\n  color: inherit !important\n}\n\n.conum:not([data-value]):empty {\n  display: none\n}\n\n/* Callout list */\n.hdlist > table, .colist > table {\n  border: 0;\n  background: none\n}\n\n.hdlist > table > tbody > tr, .colist > table > tbody > tr {\n  background: none\n}\n\ntd.hdlist1, td.hdlist2 {\n  vertical-align: top;\n  padding: 0 .625em\n}\n\ntd.hdlist1 {\n  font-weight: bold;\n  padding-bottom: 1.25em\n}\n\n/* Disabled from Asciidoctor CSS because it caused callout list to go under the\n * source listing when .stretch is applied (see #335)\n * .literalblock+.colist,.listingblock+.colist{margin-top:-.5em} */\n.colist td:not([class]):first-child {\n  padding: .4em .75em 0;\n  line-height: 1;\n  vertical-align: top\n}\n\n.colist td:not([class]):first-child img {\n  max-width: none\n}\n\n.colist td:not([class]):last-child {\n  padding: .25em 0\n}\n\n/* Override Asciidoctor CSS that causes issues with reveal.js features */\n.reveal .hljs table {\n  border: 0\n}\n\n/* Callout list rows would have a bottom border with some reveal.js themes (see #335) */\n.reveal .colist > table th, .reveal .colist > table td {\n  border-bottom: 0\n}\n\n/* Fixes line height with Highlight.js source listing when linenums enabled (see #331) */\n.reveal .hljs table thead tr th, .reveal .hljs table tfoot tr th, .reveal .hljs table tbody tr td, .reveal .hljs table tr td, .reveal .hljs table tfoot tr td {\n  line-height: inherit\n}\n\n/* Columns layout */\n.columns .slide-content {\n  display: flex;\n}\n\n.columns.wrap .slide-content {\n  flex-wrap: wrap;\n}\n\n.columns.is-vcentered .slide-content {\n  align-items: center;\n}\n\n.columns .slide-content > .column {\n  display: block;\n  flex-basis: 0;\n  flex-grow: 1;\n  flex-shrink: 1;\n}\n\n.columns .slide-content > .column > * {\n  padding: .75rem;\n}\n\n/* See #353 */\n.columns.wrap .slide-content > .column {\n  flex-basis: auto;\n}\n\n.columns .slide-content > .column.is-full {\n  flex: none;\n  width: 100%;\n}\n\n.columns .slide-content > .column.is-four-fifths {\n  flex: none;\n  width: 80%;\n}\n\n.columns .slide-content > .column.is-three-quarters {\n  flex: none;\n  width: 75%;\n}\n\n.columns .slide-content > .column.is-two-thirds {\n  flex: none;\n  width: 66.6666%;\n}\n\n.columns .slide-content > .column.is-three-fifths {\n  flex: none;\n  width: 60%;\n}\n\n.columns .slide-content > .column.is-half {\n  flex: none;\n  width: 50%;\n}\n\n.columns .slide-content > .column.is-two-fifths {\n  flex: none;\n  width: 40%;\n}\n\n.columns .slide-content > .column.is-one-third {\n  flex: none;\n  width: 33.3333%;\n}\n\n.columns .slide-content > .column.is-one-quarter {\n  flex: none;\n  width: 25%;\n}\n\n.columns .slide-content > .column.is-one-fifth {\n  flex: none;\n  width: 20%;\n}\n\n.columns .slide-content > .column.has-text-left {\n  text-align: left;\n}\n\n.columns .slide-content > .column.has-text-justified {\n  text-align: justify;\n}\n\n.columns .slide-content > .column.has-text-right {\n  text-align: right;\n}\n\n.columns .slide-content > .column.has-text-left {\n  text-align: left;\n}\n\n.columns .slide-content > .column.has-text-justified {\n  text-align: justify;\n}\n\n.columns .slide-content > .column.has-text-right {\n  text-align: right;\n}\n\n.text-left {\n  text-align: left !important\n}\n\n.text-right {\n  text-align: right !important\n}\n\n.text-center {\n  text-align: center !important\n}\n\n.text-justify {\n  text-align: justify !important\n}\n\n.footnotes {\n  border-top: 1px solid rgba(0, 0, 0, 0.2);\n  padding: 0.5em 0 0 0;\n  font-size: 0.65em;\n  margin-top: 4em;\n}\n\n.byline {\n  font-size:.8em\n}\nul.byline {\n  list-style-type: none;\n}\nul.byline li + li {\n  margin-top: 0.25em;\n}\n</style>"); 
      ; 
      ; 
      ; 
      ; if attr? :icons, 'font'; 
      ; 
      ; if attr? 'iconfont-remote'; 
      ; if (iconfont_cdn = (attr 'iconfont-cdn')); 
      ; _buf << ("<link rel=\"stylesheet\""); _slim_codeattributes20 = iconfont_cdn; if _slim_codeattributes20; if _slim_codeattributes20 == true; _buf << (" href"); else; _buf << (" href=\""); _buf << (_slim_codeattributes20); _buf << ("\""); end; end; _buf << (">"); 
      ; else; 
      ; 
      ; font_awesome_version = (attr 'font-awesome-version', '5.15.1'); 
      ; _buf << ("<link rel=\"stylesheet\""); _slim_codeattributes21 = %(#{cdn_base}/font-awesome/#{font_awesome_version}/css/all.min.css); if _slim_codeattributes21; if _slim_codeattributes21 == true; _buf << (" href"); else; _buf << (" href=\""); _buf << (_slim_codeattributes21); _buf << ("\""); end; end; _buf << ("><link rel=\"stylesheet\""); 
      ; _slim_codeattributes22 = %(#{cdn_base}/font-awesome/#{font_awesome_version}/css/v4-shims.min.css); if _slim_codeattributes22; if _slim_codeattributes22 == true; _buf << (" href"); else; _buf << (" href=\""); _buf << (_slim_codeattributes22); _buf << ("\""); end; end; _buf << (">"); 
      ; end; else; 
      ; _buf << ("<link rel=\"stylesheet\""); _slim_codeattributes23 = (normalize_web_path %(#{attr 'iconfont-name', 'font-awesome'}.css), (attr 'stylesdir', ''), false); if _slim_codeattributes23; if _slim_codeattributes23 == true; _buf << (" href"); else; _buf << (" href=\""); _buf << (_slim_codeattributes23); _buf << ("\""); end; end; _buf << (">"); 
      ; end; end; _buf << (generate_stem(cdn_base)); 
      ; syntax_hl = self.syntax_highlighter; 
      ; if syntax_hl && (syntax_hl.docinfo? :head); 
      ; _buf << (syntax_hl.docinfo :head, self, cdn_base_url: cdn_base, linkcss: linkcss, self_closing_tag_slash: '/'); 
      ; end; if attr? :customcss; 
      ; _buf << ("<link rel=\"stylesheet\""); _slim_codeattributes24 = ((customcss = attr :customcss).empty? ? 'asciidoctor-revealjs.css' : customcss); if _slim_codeattributes24; if _slim_codeattributes24 == true; _buf << (" href"); else; _buf << (" href=\""); _buf << (_slim_codeattributes24); _buf << ("\""); end; end; _buf << (">"); 
      ; end; unless (_docinfo = docinfo :head, '-revealjs.html').empty?; 
      ; _buf << (_docinfo); 
      ; end; _buf << ("</head><body><div class=\"reveal\"><div class=\"slides\">"); 
      ; 
      ; 
      ; 
      ; yield_content :slides; 
      ; _buf << ("</div></div><script src=\""); _buf << (revealjsdir); _buf << ("/dist/reveal.js\"></script><script>Array.prototype.slice.call(document.querySelectorAll('.slides section')).forEach(function(slide) {\n  if (slide.getAttribute('data-background-color')) return;\n  // user needs to explicitly say he wants CSS color to override otherwise we might break custom css or theme (#226)\n  if (!(slide.classList.contains('canvas') || slide.classList.contains('background'))) return;\n  var bgColor = getComputedStyle(slide).backgroundColor;\n  if (bgColor !== 'rgba(0, 0, 0, 0)' && bgColor !== 'transparent') {\n    slide.setAttribute('data-background-color', bgColor);\n    slide.style.backgroundColor = 'transparent';\n  }\n});\n\n// More info about config & dependencies:\n// - https://github.com/hakimel/reveal.js#configuration\n// - https://github.com/hakimel/reveal.js#dependencies\nReveal.initialize({\n  // Display presentation control arrows\n  controls: "); 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_controls', true)); _buf << (",\n  // Help the user learn the controls by providing hints, for example by\n  // bouncing the down arrow when they first encounter a vertical slide\n  controlsTutorial: "); 
      ; 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_controlstutorial', true)); _buf << (",\n  // Determines where controls appear, \"edges\" or \"bottom-right\"\n  controlsLayout: '"); 
      ; 
      ; _buf << (attr 'revealjs_controlslayout', 'bottom-right'); _buf << ("',\n  // Visibility rule for backwards navigation arrows; \"faded\", \"hidden\"\n  // or \"visible\"\n  controlsBackArrows: '"); 
      ; 
      ; 
      ; _buf << (attr 'revealjs_controlsbackarrows', 'faded'); _buf << ("',\n  // Display a presentation progress bar\n  progress: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_progress', true)); _buf << (",\n  // Display the page number of the current slide\n  slideNumber: "); 
      ; 
      ; _buf << (to_valid_slidenumber(attr 'revealjs_slidenumber', false)); _buf << (",\n  // Control which views the slide number displays on\n  showSlideNumber: '"); 
      ; 
      ; _buf << (attr 'revealjs_showslidenumber', 'all'); _buf << ("',\n  // Add the current slide number to the URL hash so that reloading the\n  // page/copying the URL will return you to the same slide\n  hash: "); 
      ; 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_hash', false)); _buf << (",\n  // Push each slide change to the browser history. Implies `hash: true`\n  history: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_history', false)); _buf << (",\n  // Enable keyboard shortcuts for navigation\n  keyboard: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_keyboard', true)); _buf << (",\n  // Enable the slide overview mode\n  overview: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_overview', true)); _buf << (",\n  // Disables the default reveal.js slide layout so that you can use custom CSS layout\n  disableLayout: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_disablelayout', false)); _buf << (",\n  // Vertical centering of slides\n  center: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_center', true)); _buf << (",\n  // Enables touch navigation on devices with touch input\n  touch: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_touch', true)); _buf << (",\n  // Loop the presentation\n  loop: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_loop', false)); _buf << (",\n  // Change the presentation direction to be RTL\n  rtl: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_rtl', false)); _buf << (",\n  // See https://github.com/hakimel/reveal.js/#navigation-mode\n  navigationMode: '"); 
      ; 
      ; _buf << (attr 'revealjs_navigationmode', 'default'); _buf << ("',\n  // Randomizes the order of slides each time the presentation loads\n  shuffle: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_shuffle', false)); _buf << (",\n  // Turns fragments on and off globally\n  fragments: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_fragments', true)); _buf << (",\n  // Flags whether to include the current fragment in the URL,\n  // so that reloading brings you to the same fragment position\n  fragmentInURL: "); 
      ; 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_fragmentinurl', false)); _buf << (",\n  // Flags if the presentation is running in an embedded mode,\n  // i.e. contained within a limited portion of the screen\n  embedded: "); 
      ; 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_embedded', false)); _buf << (",\n  // Flags if we should show a help overlay when the questionmark\n  // key is pressed\n  help: "); 
      ; 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_help', true)); _buf << (",\n  // Flags if speaker notes should be visible to all viewers\n  showNotes: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_shownotes', false)); _buf << (",\n  // Global override for autolaying embedded media (video/audio/iframe)\n  // - null: Media will only autoplay if data-autoplay is present\n  // - true: All media will autoplay, regardless of individual setting\n  // - false: No media will autoplay, regardless of individual setting\n  autoPlayMedia: "); 
      ; 
      ; 
      ; 
      ; 
      ; _buf << (attr 'revealjs_autoplaymedia', 'null'); _buf << (",\n  // Global override for preloading lazy-loaded iframes\n  // - null: Iframes with data-src AND data-preload will be loaded when within\n  //   the viewDistance, iframes with only data-src will be loaded when visible\n  // - true: All iframes with data-src will be loaded when within the viewDistance\n  // - false: All iframes with data-src will be loaded only when visible\n  preloadIframes: "); 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf << (attr 'revealjs_preloadiframes', 'null'); _buf << (",\n  // Number of milliseconds between automatically proceeding to the\n  // next slide, disabled when set to 0, this value can be overwritten\n  // by using a data-autoslide attribute on your slides\n  autoSlide: "); 
      ; 
      ; 
      ; 
      ; _buf << (attr 'revealjs_autoslide', 0); _buf << (",\n  // Stop auto-sliding after user input\n  autoSlideStoppable: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_autoslidestoppable', true)); _buf << (",\n  // Use this method for navigation when auto-sliding\n  autoSlideMethod: "); 
      ; 
      ; _buf << (attr 'revealjs_autoslidemethod', 'Reveal.navigateNext'); _buf << (",\n  // Specify the average time in seconds that you think you will spend\n  // presenting each slide. This is used to show a pacing timer in the\n  // speaker view\n  defaultTiming: "); 
      ; 
      ; 
      ; 
      ; _buf << (attr 'revealjs_defaulttiming', 120); _buf << (",\n  // Specify the total time in seconds that is available to\n  // present.  If this is set to a nonzero value, the pacing\n  // timer will work out the time available for each slide,\n  // instead of using the defaultTiming value\n  totalTime: "); 
      ; 
      ; 
      ; 
      ; 
      ; _buf << (attr 'revealjs_totaltime', 0); _buf << (",\n  // Specify the minimum amount of time you want to allot to\n  // each slide, if using the totalTime calculation method.  If\n  // the automated time allocation causes slide pacing to fall\n  // below this threshold, then you will see an alert in the\n  // speaker notes window\n  minimumTimePerSlide: "); 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf << (attr 'revealjs_minimumtimeperslide', 0); _buf << (",\n  // Enable slide navigation via mouse wheel\n  mouseWheel: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_mousewheel', false)); _buf << (",\n  // Hide cursor if inactive\n  hideInactiveCursor: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_hideinactivecursor', true)); _buf << (",\n  // Time before the cursor is hidden (in ms)\n  hideCursorTime: "); 
      ; 
      ; _buf << (attr 'revealjs_hidecursortime', 5000); _buf << (",\n  // Hides the address bar on mobile devices\n  hideAddressBar: "); 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_hideaddressbar', true)); _buf << (",\n  // Opens links in an iframe preview overlay\n  // Add `data-preview-link` and `data-preview-link=\"false\"` to customise each link\n  // individually\n  previewLinks: "); 
      ; 
      ; 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_previewlinks', false)); _buf << (",\n  // Transition style (e.g., none, fade, slide, convex, concave, zoom)\n  transition: '"); 
      ; 
      ; _buf << (attr 'revealjs_transition', 'slide'); _buf << ("',\n  // Transition speed (e.g., default, fast, slow)\n  transitionSpeed: '"); 
      ; 
      ; _buf << (attr 'revealjs_transitionspeed', 'default'); _buf << ("',\n  // Transition style for full page slide backgrounds (e.g., none, fade, slide, convex, concave, zoom)\n  backgroundTransition: '"); 
      ; 
      ; _buf << (attr 'revealjs_backgroundtransition', 'fade'); _buf << ("',\n  // Number of slides away from the current that are visible\n  viewDistance: "); 
      ; 
      ; _buf << (attr 'revealjs_viewdistance', 3); _buf << (",\n  // Number of slides away from the current that are visible on mobile\n  // devices. It is advisable to set this to a lower number than\n  // viewDistance in order to save resources.\n  mobileViewDistance: "); 
      ; 
      ; 
      ; 
      ; _buf << (attr 'revealjs_mobileviewdistance', 3); _buf << (",\n  // Parallax background image (e.g., \"'https://s3.amazonaws.com/hakim-static/reveal-js/reveal-parallax-1.jpg'\")\n  parallaxBackgroundImage: '"); 
      ; 
      ; _buf << (attr 'revealjs_parallaxbackgroundimage', ''); _buf << ("',\n  // Parallax background size in CSS syntax (e.g., \"2100px 900px\")\n  parallaxBackgroundSize: '"); 
      ; 
      ; _buf << (attr 'revealjs_parallaxbackgroundsize', ''); _buf << ("',\n  // Number of pixels to move the parallax background per slide\n  // - Calculated automatically unless specified\n  // - Set to 0 to disable movement along an axis\n  parallaxBackgroundHorizontal: "); 
      ; 
      ; 
      ; 
      ; _buf << (attr 'revealjs_parallaxbackgroundhorizontal', 'null'); _buf << (",\n  parallaxBackgroundVertical: "); 
      ; _buf << (attr 'revealjs_parallaxbackgroundvertical', 'null'); _buf << (",\n  // The display mode that will be used to show slides\n  display: '"); 
      ; 
      ; _buf << (attr 'revealjs_display', 'block'); _buf << ("',\n\n  // The \"normal\" size of the presentation, aspect ratio will be preserved\n  // when the presentation is scaled to fit different resolutions. Can be\n  // specified using percentage units.\n  width: "); 
      ; 
      ; 
      ; 
      ; 
      ; _buf << (attr 'revealjs_width', 960); _buf << (",\n  height: "); 
      ; _buf << (attr 'revealjs_height', 700); _buf << (",\n\n  // Factor of the display size that should remain empty around the content\n  margin: "); 
      ; 
      ; 
      ; _buf << (attr 'revealjs_margin', 0.1); _buf << (",\n\n  // Bounds for smallest/largest possible scale to apply to content\n  minScale: "); 
      ; 
      ; 
      ; _buf << (attr 'revealjs_minscale', 0.2); _buf << (",\n  maxScale: "); 
      ; _buf << (attr 'revealjs_maxscale', 1.5); _buf << (",\n\n  // PDF Export Options\n  // Put each fragment on a separate page\n  pdfSeparateFragments: "); 
      ; 
      ; 
      ; 
      ; _buf << (to_boolean(attr 'revealjs_pdfseparatefragments', true)); _buf << (",\n  // For slides that do not fit on a page, max number of pages\n  pdfMaxPagesPerSlide: "); 
      ; 
      ; _buf << (attr 'revealjs_pdfmaxpagesperslide', 1); _buf << (",\n\n  // Optional libraries used to extend on reveal.js\n  dependencies: [\n      "); 
      ; 
      ; 
      ; 
      ; _buf << (revealjs_dependencies(document, self, revealjsdir)); 
      ; _buf << ("\n  ],\n});</script><script>var dom = {};\ndom.slides = document.querySelector('.reveal .slides');\n\nfunction getRemainingHeight(element, slideElement, height) {\n  height = height || 0;\n  if (element) {\n    var newHeight, oldHeight = element.style.height;\n    // Change the .stretch element height to 0 in order find the height of all\n    // the other elements\n    element.style.height = '0px';\n    // In Overview mode, the parent (.slide) height is set of 700px.\n    // Restore it temporarily to its natural height.\n    slideElement.style.height = 'auto';\n    newHeight = height - slideElement.offsetHeight;\n    // Restore the old height, just in case\n    element.style.height = oldHeight + 'px';\n    // Clear the parent (.slide) height. .removeProperty works in IE9+\n    slideElement.style.removeProperty('height');\n    return newHeight;\n  }\n  return height;\n}\n\nfunction layoutSlideContents(width, height) {\n  // Handle sizing of elements with the 'stretch' class\n  toArray(dom.slides.querySelectorAll('section .stretch')).forEach(function (element) {\n    // Determine how much vertical space we can use\n    var limit = 5; // hard limit\n    var parent = element.parentNode;\n    while (parent.nodeName !== 'SECTION' && limit > 0) {\n      parent = parent.parentNode;\n      limit--;\n    }\n    if (limit === 0) {\n      // unable to find parent, aborting!\n      return;\n    }\n    var remainingHeight = getRemainingHeight(element, parent, height);\n    // Consider the aspect ratio of media elements\n    if (/(img|video)/gi.test(element.nodeName)) {\n      var nw = element.naturalWidth || element.videoWidth, nh = element.naturalHeight || element.videoHeight;\n      var es = Math.min(width / nw, remainingHeight / nh);\n      element.style.width = (nw * es) + 'px';\n      element.style.height = (nh * es) + 'px';\n    } else {\n      element.style.width = width + 'px';\n      element.style.height = remainingHeight + 'px';\n    }\n  });\n}\n\nfunction toArray(o) {\n  return Array.prototype.slice.call(o);\n}\n\nReveal.addEventListener('slidechanged', function () {\n  layoutSlideContents("); 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf << (attr 'revealjs_width', 960); _buf << (", "); _buf << (attr 'revealjs_height', 700); _buf << (")\n});\nReveal.addEventListener('ready', function () {\n  layoutSlideContents("); 
      ; 
      ; 
      ; _buf << (attr 'revealjs_width', 960); _buf << (", "); _buf << (attr 'revealjs_height', 700); _buf << (")\n});\nReveal.addEventListener('resize', function () {\n  layoutSlideContents("); 
      ; 
      ; 
      ; _buf << (attr 'revealjs_width', 960); _buf << (", "); _buf << (attr 'revealjs_height', 700); _buf << (")\n});</script>"); 
      ; 
      ; 
      ; if syntax_hl && (syntax_hl.docinfo? :footer); 
      ; _buf << (syntax_hl.docinfo :footer, self, cdn_base_url: cdn_base, linkcss: linkcss, self_closing_tag_slash: '/'); 
      ; 
      ; end; unless (docinfo_content = (docinfo :footer, '.html')).empty?; 
      ; _buf << (docinfo_content); 
      ; end; _buf << ("</body></html>"); _buf = _buf.join("")
    end
  end

  def convert_embedded(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; unless notitle || !has_header?; 
      ; _buf << ("<h1"); _slim_codeattributes1 = @id; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes1); _buf << ("\""); end; end; _buf << (">"); _buf << (@header.title); 
      ; _buf << ("</h1>"); end; _buf << (content); 
      ; unless !footnotes? || attr?(:nofootnotes); 
      ; _buf << ("<div id=\"footnotes\"><hr>"); 
      ; 
      ; footnotes.each do |fn|; 
      ; _buf << ("<div class=\"footnote\" id=\"_footnote_"); _buf << (fn.index); _buf << ("\"><a href=\"#_footnoteref_"); 
      ; _buf << (fn.index); _buf << ("\">"); _buf << (fn.index); _buf << ("</a>. "); _buf << (fn.text); 
      ; _buf << ("</div>"); end; _buf << ("</div>"); end; _buf = _buf.join("")
    end
  end

  def convert_example(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _slim_controls1 = html_tag('div', { :id => @id, :class => ['exampleblock', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (captioned_title); 
      ; _slim_controls2 << ("</div>"); end; _slim_controls2 << ("<div class=\"content\">"); _slim_controls2 << (content); 
      ; _slim_controls2 << ("</div>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def convert_floating_title(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _slim_htag_filter1 = ((level + 1)).to_s; _buf << ("<h"); _buf << (_slim_htag_filter1); _slim_codeattributes1 = id; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes1); _buf << ("\""); end; end; _temple_html_attributeremover1 = []; _slim_codeattributes2 = [style, role]; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes2.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes2); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _buf << (">"); 
      ; _buf << (title); 
      ; _buf << ("</h"); _buf << (_slim_htag_filter1); _buf << (">"); _buf = _buf.join("")
    end
  end

  def convert_image(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; unless attributes[1] == 'background' || attributes[1] == 'canvas'; 
      ; inline_style = [("text-align: #{attr :align}" if attr? :align),("float: #{attr :float}" if attr? :float)].compact.join('; '); 
      ; _slim_controls1 = html_tag('div', { :id => @id, :class => ['imageblock', role, ('fragment' if (option? :step) || (attr? 'step'))], :style => inline_style }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; _slim_controls2 << (convert_image); 
      ; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); if title?; 
      ; _buf << ("<div class=\"title\">"); _buf << (captioned_title); 
      ; _buf << ("</div>"); end; end; _buf = _buf.join("")
    end
  end

  def convert_inline_anchor(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; case @type; 
      ; when :xref; 
      ; refid = (attr :refid) || @target; 
      ; _slim_controls1 = html_tag('a', { :href => @target, :class => [role, ('fragment' if (option? :step) || (attr? 'step'))].compact }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; _slim_controls2 << ((@text || @document.references[:ids].fetch(refid, "[#{refid}]")).tr_s("\n", ' ')); 
      ; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); when :ref; 
      ; _buf << (html_tag('a', { :id => @target }.merge(data_attrs(@attributes)))); 
      ; when :bibref; 
      ; _buf << (html_tag('a', { :id => @target }.merge(data_attrs(@attributes)))); 
      ; _buf << ("["); _buf << (@target); _buf << ("]"); 
      ; else; 
      ; _slim_controls3 = html_tag('a', { :href => @target, :class => [role, ('fragment' if (option? :step) || (attr? 'step'))].compact, :target => (attr :window), 'data-preview-link' => (bool_data_attr :preview) }.merge(data_attrs(@attributes))) do; _slim_controls4 = []; 
      ; _slim_controls4 << (@text); 
      ; _slim_controls4 = _slim_controls4.join(""); end; _buf << (_slim_controls3); end; _buf = _buf.join("")
    end
  end

  def convert_inline_break(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _buf << (@text); 
      ; _buf << ("<br>"); 
      ; _buf = _buf.join("")
    end
  end

  def convert_inline_button(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _slim_controls1 = html_tag('b', { :class => ['button'] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; _slim_controls2 << (@text); 
      ; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def convert_inline_callout(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; if @document.attr? :icons, 'font'; 
      ; _buf << ("<i class=\"conum\""); _slim_codeattributes1 = @text; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" data-value"); else; _buf << (" data-value=\""); _buf << (_slim_codeattributes1); _buf << ("\""); end; end; _buf << ("></i><b>"); 
      ; _buf << ("(#{@text})"); 
      ; _buf << ("</b>"); elsif @document.attr? :icons; 
      ; _buf << ("<img"); _slim_codeattributes2 = icon_uri("callouts/#{@text}"); if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" src"); else; _buf << (" src=\""); _buf << (_slim_codeattributes2); _buf << ("\""); end; end; _slim_codeattributes3 = @text; if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" alt"); else; _buf << (" alt=\""); _buf << (_slim_codeattributes3); _buf << ("\""); end; end; _buf << (">"); 
      ; else; 
      ; _buf << ("<b>"); _buf << ("(#{@text})"); 
      ; _buf << ("</b>"); end; _buf = _buf.join("")
    end
  end

  def convert_inline_footnote(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; footnote = slide_footnote(self); 
      ; index = footnote.attr(:index); 
      ; id = footnote.id; 
      ; if @type == :xref; 
      ; _slim_controls1 = html_tag('sup', { :class => ['footnoteref'] }.merge(data_attrs(footnote.attributes))) do; _slim_controls2 = []; 
      ; _slim_controls2 << ("[<span class=\"footnote\" title=\"View footnote.\">"); 
      ; _slim_controls2 << (index); 
      ; _slim_controls2 << ("</span>]"); 
      ; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); else; 
      ; _slim_controls3 = html_tag('sup', { :id => ("_footnote_#{id}" if id), :class => ['footnote'] }.merge(data_attrs(footnote.attributes))) do; _slim_controls4 = []; 
      ; _slim_controls4 << ("[<span class=\"footnote\" title=\"View footnote.\">"); 
      ; _slim_controls4 << (index); 
      ; _slim_controls4 << ("</span>]"); 
      ; _slim_controls4 = _slim_controls4.join(""); end; _buf << (_slim_controls3); end; _buf = _buf.join("")
    end
  end

  def convert_inline_image(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _slim_controls1 = html_tag('span', { :class => [@type, role, ('fragment' if (option? :step) || (attr? 'step'))], :style => ("float: #{attr :float}" if attr? :float) }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; _slim_controls2 << (convert_inline_image); 
      ; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def convert_inline_indexterm(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; if @type == :visible; 
      ; _buf << (@text); 
      ; end; _buf = _buf.join("")
    end
  end

  def convert_inline_kbd(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; if (keys = attr 'keys').size == 1; 
      ; _slim_controls1 = html_tag('kbd', data_attrs(@attributes)) do; _slim_controls2 = []; 
      ; _slim_controls2 << (keys.first); 
      ; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); else; 
      ; _slim_controls3 = html_tag('span', { :class => ['keyseq'] }.merge(data_attrs(@attributes))) do; _slim_controls4 = []; 
      ; keys.each_with_index do |key, idx|; 
      ; unless idx.zero?; 
      ; _slim_controls4 << ("+"); 
      ; end; _slim_controls4 << ("<kbd>"); _slim_controls4 << (key); 
      ; _slim_controls4 << ("</kbd>"); end; _slim_controls4 = _slim_controls4.join(""); end; _buf << (_slim_controls3); end; _buf = _buf.join("")
    end
  end

  def convert_inline_menu(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; menu = attr 'menu'; 
      ; menuitem = attr 'menuitem'; 
      ; if !(submenus = attr 'submenus').empty?; 
      ; _slim_controls1 = html_tag('span', { :class => ['menuseq'] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; _slim_controls2 << ("<span class=\"menu\">"); _slim_controls2 << (menu); 
      ; _slim_controls2 << ("</span>&#160;&#9656;&#32;"); 
      ; _slim_controls2 << (submenus.map {|submenu| %(<span class="submenu">#{submenu}</span>&#160;&#9656;&#32;) }.join); 
      ; _slim_controls2 << ("<span class=\"menuitem\">"); _slim_controls2 << (menuitem); 
      ; _slim_controls2 << ("</span>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); elsif !menuitem.nil?; 
      ; _slim_controls3 = html_tag('span', { :class => ['menuseq'] }.merge(data_attrs(@attributes))) do; _slim_controls4 = []; 
      ; _slim_controls4 << ("<span class=\"menu\">"); _slim_controls4 << (menu); 
      ; _slim_controls4 << ("</span>&#160;&#9656;&#32;<span class=\"menuitem\">"); 
      ; _slim_controls4 << (menuitem); 
      ; _slim_controls4 << ("</span>"); _slim_controls4 = _slim_controls4.join(""); end; _buf << (_slim_controls3); else; 
      ; _slim_controls5 = html_tag('span', { :class => ['menu'] }.merge(data_attrs(@attributes))) do; _slim_controls6 = []; 
      ; _slim_controls6 << (menu); 
      ; _slim_controls6 = _slim_controls6.join(""); end; _buf << (_slim_controls5); end; _buf = _buf.join("")
    end
  end

  def convert_inline_quoted(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; quote_tags = { emphasis: 'em', strong: 'strong', monospaced: 'code', superscript: 'sup', subscript: 'sub' }; 
      ; if (quote_tag = quote_tags[@type]); 
      ; _buf << (html_tag(quote_tag, { :id => @id, :class => [role, ('fragment' if (option? :step) || (attr? 'step'))].compact }.merge(data_attrs(@attributes)), @text)); 
      ; else; 
      ; case @type; 
      ; when :double; 
      ; _buf << (inline_text_container("&#8220;#{@text}&#8221;")); 
      ; when :single; 
      ; _buf << (inline_text_container("&#8216;#{@text}&#8217;")); 
      ; when :asciimath, :latexmath; 
      ; open, close = Asciidoctor::INLINE_MATH_DELIMITERS[@type]; 
      ; _buf << (inline_text_container("#{open}#{@text}#{close}")); 
      ; else; 
      ; _buf << (inline_text_container(@text)); 
      ; end; end; _buf = _buf.join("")
    end
  end

  def convert_listing(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; nowrap = (option? 'nowrap') || !(document.attr? 'prewrap'); 
      ; if @style == 'source'; 
      ; syntax_hl = document.syntax_highlighter; 
      ; lang = attr :language; 
      ; if syntax_hl; 
      ; doc_attrs = document.attributes; 
      ; css_mode = (doc_attrs[%(#{syntax_hl.name}-css)] || :class).to_sym; 
      ; style = doc_attrs[%(#{syntax_hl.name}-style)]; 
      ; opts = syntax_hl.highlight? ? { css_mode: css_mode, style: style } : {}; 
      ; opts[:nowrap] = nowrap; 
      ; end; 
      ; end; _slim_controls1 = html_tag('div', { :id => id, :class => ['listingblock', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes.reject {|key, _| key == 'data-id' }))) do; _slim_controls2 = []; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (captioned_title); 
      ; _slim_controls2 << ("</div>"); end; _slim_controls2 << ("<div class=\"content\">"); 
      ; if syntax_hl; 
      ; _slim_controls2 << ((syntax_hl.format self, lang, opts)); 
      ; else; 
      ; if @style == 'source'; 
      ; _slim_controls2 << ("<pre"); _temple_html_attributeremover1 = []; _slim_codeattributes1 = ['highlight', ('nowrap' if nowrap)]; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes1.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes1); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover1); _slim_controls2 << ("\""); end; _slim_controls2 << ("><code"); 
      ; _temple_html_attributeremover2 = []; _slim_codeattributes2 = [("language-#{lang}" if lang)]; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover2 << (_slim_codeattributes2.join(" ")); else; _temple_html_attributeremover2 << (_slim_codeattributes2); end; _temple_html_attributeremover2 = _temple_html_attributeremover2.join(""); if !_temple_html_attributeremover2.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover2); _slim_controls2 << ("\""); end; _slim_codeattributes3 = ("#{lang}" if lang); if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" data-lang"); else; _slim_controls2 << (" data-lang=\""); _slim_controls2 << (_slim_codeattributes3); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">"); 
      ; _slim_controls2 << (content || ''); 
      ; _slim_controls2 << ("</code></pre>"); else; 
      ; _slim_controls2 << ("<pre"); _temple_html_attributeremover3 = []; _slim_codeattributes4 = [('nowrap' if nowrap)]; if Array === _slim_codeattributes4; _slim_codeattributes4 = _slim_codeattributes4.flatten; _slim_codeattributes4.map!(&:to_s); _slim_codeattributes4.reject!(&:empty?); _temple_html_attributeremover3 << (_slim_codeattributes4.join(" ")); else; _temple_html_attributeremover3 << (_slim_codeattributes4); end; _temple_html_attributeremover3 = _temple_html_attributeremover3.join(""); if !_temple_html_attributeremover3.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover3); _slim_controls2 << ("\""); end; _slim_controls2 << (">"); 
      ; _slim_controls2 << (content || ''); 
      ; _slim_controls2 << ("</pre>"); end; end; _slim_controls2 << ("</div>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def convert_literal(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _slim_controls1 = html_tag('div', { :id => id, :class => ['literalblock', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (title); 
      ; _slim_controls2 << ("</div>"); end; _slim_controls2 << ("<div class=\"content\"><pre"); _temple_html_attributeremover1 = []; _slim_codeattributes1 = (!(@document.attr? :prewrap) || (option? 'nowrap') ? 'nowrap' : nil); if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes1.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes1); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover1); _slim_controls2 << ("\""); end; _slim_controls2 << (">"); _slim_controls2 << (content); 
      ; _slim_controls2 << ("</pre></div>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def convert_notes(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _buf << ("<aside class=\"notes\">"); _buf << (resolve_content); 
      ; _buf << ("</aside>"); _buf = _buf.join("")
    end
  end

  def convert_olist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _slim_controls1 = html_tag('div', { :id => @id, :class => ['olist', @style, role] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (title); 
      ; _slim_controls2 << ("</div>"); end; _slim_controls2 << ("<ol"); _temple_html_attributeremover1 = []; _slim_codeattributes1 = @style; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes1.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes1); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover1); _slim_controls2 << ("\""); end; _slim_codeattributes2 = (attr :start); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls2 << (" start"); else; _slim_controls2 << (" start=\""); _slim_controls2 << (_slim_codeattributes2); _slim_controls2 << ("\""); end; end; _slim_codeattributes3 = list_marker_keyword; if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" type"); else; _slim_controls2 << (" type=\""); _slim_controls2 << (_slim_codeattributes3); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">"); 
      ; items.each do |item|; 
      ; _slim_controls2 << ("<li"); _temple_html_attributeremover2 = []; _slim_codeattributes4 = ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step')); if Array === _slim_codeattributes4; _slim_codeattributes4 = _slim_codeattributes4.flatten; _slim_codeattributes4.map!(&:to_s); _slim_codeattributes4.reject!(&:empty?); _temple_html_attributeremover2 << (_slim_codeattributes4.join(" ")); else; _temple_html_attributeremover2 << (_slim_codeattributes4); end; _temple_html_attributeremover2 = _temple_html_attributeremover2.join(""); if !_temple_html_attributeremover2.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover2); _slim_controls2 << ("\""); end; _slim_controls2 << ("><p>"); 
      ; _slim_controls2 << (item.text); 
      ; _slim_controls2 << ("</p>"); if item.blocks?; 
      ; _slim_controls2 << (item.content); 
      ; end; _slim_controls2 << ("</li>"); end; _slim_controls2 << ("</ol>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def convert_open(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; if @style == 'abstract'; 
      ; if @parent == @document && @document.doctype == 'book'; 
      ; puts 'asciidoctor: WARNING: abstract block cannot be used in a document without a title when doctype is book. Excluding block content.'; 
      ; else; 
      ; _slim_controls1 = html_tag('div', { :id => @id, :class => ['quoteblock', 'abstract', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (title); 
      ; _slim_controls2 << ("</div>"); end; _slim_controls2 << ("<blockquote>"); _slim_controls2 << (content); 
      ; _slim_controls2 << ("</blockquote>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); end; elsif @style == 'partintro' && (@level != 0 || @parent.context != :section || @document.doctype != 'book'); 
      ; puts 'asciidoctor: ERROR: partintro block can only be used when doctype is book and it\'s a child of a book part. Excluding block content.'; 
      ; else; 
      ; if (has_role? 'aside') or (has_role? 'speaker') or (has_role? 'notes'); 
      ; _buf << ("<aside class=\"notes\">"); _buf << (resolve_content); 
      ; _buf << ("</aside>"); 
      ; else; 
      ; _slim_controls3 = html_tag('div', { :id => @id, :class => ['openblock', (@style != 'open' ? @style : nil), role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls4 = []; 
      ; if title?; 
      ; _slim_controls4 << ("<div class=\"title\">"); _slim_controls4 << (title); 
      ; _slim_controls4 << ("</div>"); end; _slim_controls4 << ("<div class=\"content\">"); _slim_controls4 << (content); 
      ; _slim_controls4 << ("</div>"); _slim_controls4 = _slim_controls4.join(""); end; _buf << (_slim_controls3); end; end; _buf = _buf.join("")
    end
  end

  def convert_outline(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; unless sections.empty?; 
      ; toclevels ||= (document.attr 'toclevels', DEFAULT_TOCLEVELS).to_i; 
      ; slevel = section_level sections.first; 
      ; _buf << ("<ol class=\"sectlevel"); _buf << (slevel); _buf << ("\">"); 
      ; sections.each do |sec|; 
      ; _buf << ("<li><a href=\"#"); 
      ; _buf << (sec.id); _buf << ("\">"); _buf << (section_title sec); 
      ; _buf << ("</a>"); if (sec.level < toclevels) && (child_toc = converter.convert sec, 'outline'); 
      ; _buf << (child_toc); 
      ; end; _buf << ("</li>"); end; _buf << ("</ol>"); end; _buf = _buf.join("")
    end
  end

  def convert_page_break(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _buf << ("<div style=\"page-break-after: always;\"></div>"); 
      ; _buf = _buf.join("")
    end
  end

  def convert_paragraph(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _slim_controls1 = html_tag('div', { :id => @id, :class => ['paragraph', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (title); 
      ; _slim_controls2 << ("</div>"); end; if has_role? 'small'; 
      ; _slim_controls2 << ("<small>"); _slim_controls2 << (content); 
      ; _slim_controls2 << ("</small>"); else; 
      ; _slim_controls2 << ("<p>"); _slim_controls2 << (content); 
      ; _slim_controls2 << ("</p>"); end; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def convert_pass(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _buf << (content); 
      ; _buf = _buf.join("")
    end
  end

  def convert_preamble(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; 
      ; 
      ; _buf = _buf.join("")
    end
  end

  def convert_quote(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _slim_controls1 = html_tag('div', { :id => @id, :class => ['quoteblock', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (title); 
      ; _slim_controls2 << ("</div>"); end; _slim_controls2 << ("<blockquote>"); _slim_controls2 << (content); 
      ; _slim_controls2 << ("</blockquote>"); attribution = (attr? :attribution) ? (attr :attribution) : nil; 
      ; citetitle = (attr? :citetitle) ? (attr :citetitle) : nil; 
      ; if attribution || citetitle; 
      ; _slim_controls2 << ("<div class=\"attribution\">"); 
      ; if citetitle; 
      ; _slim_controls2 << ("<cite>"); _slim_controls2 << (citetitle); 
      ; _slim_controls2 << ("</cite>"); end; if attribution; 
      ; if citetitle; 
      ; _slim_controls2 << ("<br>"); 
      ; end; _slim_controls2 << ("&#8212; "); _slim_controls2 << (attribution); 
      ; end; _slim_controls2 << ("</div>"); end; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def convert_ruler(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _buf << ("<hr>"); 
      ; _buf = _buf.join("")
    end
  end

  def convert_sidebar(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; if (has_role? 'aside') or (has_role? 'speaker') or (has_role? 'notes'); 
      ; _buf << ("<aside class=\"notes\">"); _buf << (resolve_content); 
      ; _buf << ("</aside>"); 
      ; else; 
      ; _slim_controls1 = html_tag('div', { :id => @id, :class => ['sidebarblock', role, ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; _slim_controls2 << ("<div class=\"content\">"); 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (title); 
      ; _slim_controls2 << ("</div>"); end; _slim_controls2 << (content); 
      ; _slim_controls2 << ("</div>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); end; _buf = _buf.join("")
    end
  end

  def convert_stem(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; open, close = Asciidoctor::BLOCK_MATH_DELIMITERS[@style.to_sym]; 
      ; equation = content.strip; 
      ; if (@subs.nil? || @subs.empty?) && !(attr? 'subs'); 
      ; equation = sub_specialcharacters equation; 
      ; end; unless (equation.start_with? open) && (equation.end_with? close); 
      ; equation = %(#{open}#{equation}#{close}); 
      ; end; _slim_controls1 = html_tag('div', { :id => @id, :class => ['stemblock', role, ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (title); 
      ; _slim_controls2 << ("</div>"); end; _slim_controls2 << ("<div class=\"content\">"); _slim_controls2 << (equation); 
      ; _slim_controls2 << ("</div>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def convert_stretch_nested_elements(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _buf << ("<script>var dom = {};\ndom.slides = document.querySelector('.reveal .slides');\n\nfunction getRemainingHeight(element, slideElement, height) {\n  height = height || 0;\n  if (element) {\n    var newHeight, oldHeight = element.style.height;\n    // Change the .stretch element height to 0 in order find the height of all\n    // the other elements\n    element.style.height = '0px';\n    // In Overview mode, the parent (.slide) height is set of 700px.\n    // Restore it temporarily to its natural height.\n    slideElement.style.height = 'auto';\n    newHeight = height - slideElement.offsetHeight;\n    // Restore the old height, just in case\n    element.style.height = oldHeight + 'px';\n    // Clear the parent (.slide) height. .removeProperty works in IE9+\n    slideElement.style.removeProperty('height');\n    return newHeight;\n  }\n  return height;\n}\n\nfunction layoutSlideContents(width, height) {\n  // Handle sizing of elements with the 'stretch' class\n  toArray(dom.slides.querySelectorAll('section .stretch')).forEach(function (element) {\n    // Determine how much vertical space we can use\n    var limit = 5; // hard limit\n    var parent = element.parentNode;\n    while (parent.nodeName !== 'SECTION' && limit > 0) {\n      parent = parent.parentNode;\n      limit--;\n    }\n    if (limit === 0) {\n      // unable to find parent, aborting!\n      return;\n    }\n    var remainingHeight = getRemainingHeight(element, parent, height);\n    // Consider the aspect ratio of media elements\n    if (/(img|video)/gi.test(element.nodeName)) {\n      var nw = element.naturalWidth || element.videoWidth, nh = element.naturalHeight || element.videoHeight;\n      var es = Math.min(width / nw, remainingHeight / nh);\n      element.style.width = (nw * es) + 'px';\n      element.style.height = (nh * es) + 'px';\n    } else {\n      element.style.width = width + 'px';\n      element.style.height = remainingHeight + 'px';\n    }\n  });\n}\n\nfunction toArray(o) {\n  return Array.prototype.slice.call(o);\n}\n\nReveal.addEventListener('slidechanged', function () {\n  layoutSlideContents("); 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf << (attr 'revealjs_width', 960); _buf << (", "); _buf << (attr 'revealjs_height', 700); _buf << (")\n});\nReveal.addEventListener('ready', function () {\n  layoutSlideContents("); 
      ; 
      ; 
      ; _buf << (attr 'revealjs_width', 960); _buf << (", "); _buf << (attr 'revealjs_height', 700); _buf << (")\n});\nReveal.addEventListener('resize', function () {\n  layoutSlideContents("); 
      ; 
      ; 
      ; _buf << (attr 'revealjs_width', 960); _buf << (", "); _buf << (attr 'revealjs_height', 700); _buf << (")\n});</script>"); 
      ; 
      ; _buf = _buf.join("")
    end
  end

  def convert_table(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; classes = ['tableblock', "frame-#{attr :frame, 'all'}", "grid-#{attr :grid, 'all'}", role, ('fragment' if (option? :step) || (attr? 'step'))]; 
      ; styles = [("width:#{attr :tablepcwidth}%" unless option? 'autowidth'), ("float:#{attr :float}" if attr? :float)].compact.join('; '); 
      ; _slim_controls1 = html_tag('table', { :id => @id, :class => classes, :style => styles }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; if title?; 
      ; _slim_controls2 << ("<caption class=\"title\">"); _slim_controls2 << (captioned_title); 
      ; _slim_controls2 << ("</caption>"); end; unless (attr :rowcount).zero?; 
      ; _slim_controls2 << ("<colgroup>"); 
      ; if option? 'autowidth'; 
      ; @columns.each do; 
      ; _slim_controls2 << ("<col>"); 
      ; end; else; 
      ; @columns.each do |col|; 
      ; _slim_controls2 << ("<col style=\"width:"); _slim_controls2 << (col.attr :colpcwidth); _slim_controls2 << ("%\">"); 
      ; end; end; _slim_controls2 << ("</colgroup>"); [:head, :foot, :body].select {|tblsec| !@rows[tblsec].empty? }.each do |tblsec|; 
      ; 
      ; _slim_controls2 << ("<t"); _slim_controls2 << (tblsec); _slim_controls2 << (">"); 
      ; @rows[tblsec].each do |row|; 
      ; _slim_controls2 << ("<tr>"); 
      ; row.each do |cell|; 
      ; 
      ; if tblsec == :head; 
      ; cell_content = cell.text; 
      ; else; 
      ; case cell.style; 
      ; when :literal; 
      ; cell_content = cell.text; 
      ; else; 
      ; cell_content = cell.content; 
      ; end; end; _slim_controls3 = html_tag(tblsec == :head || cell.style == :header ? 'th' : 'td',
      :class=>['tableblock', "halign-#{cell.attr :halign}", "valign-#{cell.attr :valign}"],
      :colspan=>cell.colspan, :rowspan=>cell.rowspan,
      :style=>((@document.attr? :cellbgcolor) ? %(background-color:#{@document.attr :cellbgcolor};) : nil)) do; _slim_controls4 = []; 
      ; if tblsec == :head; 
      ; _slim_controls4 << (cell_content); 
      ; else; 
      ; case cell.style; 
      ; when :asciidoc; 
      ; _slim_controls4 << ("<div>"); _slim_controls4 << (cell_content); 
      ; _slim_controls4 << ("</div>"); when :literal; 
      ; _slim_controls4 << ("<div class=\"literal\"><pre>"); _slim_controls4 << (cell_content); 
      ; _slim_controls4 << ("</pre></div>"); when :header; 
      ; cell_content.each do |text|; 
      ; _slim_controls4 << ("<p class=\"tableblock header\">"); _slim_controls4 << (text); 
      ; _slim_controls4 << ("</p>"); end; else; 
      ; cell_content.each do |text|; 
      ; _slim_controls4 << ("<p class=\"tableblock\">"); _slim_controls4 << (text); 
      ; _slim_controls4 << ("</p>"); end; end; end; _slim_controls4 = _slim_controls4.join(""); end; _slim_controls2 << (_slim_controls3); end; _slim_controls2 << ("</tr>"); end; end; end; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def convert_thematic_break(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _buf << ("<hr>"); 
      ; _buf = _buf.join("")
    end
  end

  def convert_title_slide(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; bg_image = (attr? 'title-slide-background-image') ? (image_uri(attr 'title-slide-background-image')) : nil; 
      ; bg_video = (attr? 'title-slide-background-video') ? (media_uri(attr 'title-slide-background-video')) : nil; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ("<section"); _temple_html_attributeremover1 = []; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "title"; _temple_html_attributemerger1[1] = []; _slim_codeattributes1 = role; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << (_slim_codeattributes1.join(" ")); else; _temple_html_attributemerger1[1] << (_slim_codeattributes1); end; _temple_html_attributemerger1[1] = _temple_html_attributemerger1[1].join(""); _temple_html_attributeremover1 << (_temple_html_attributemerger1.reject(&:empty?).join(" ")); _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _buf << (" data-state=\"title\""); _slim_codeattributes2 = (attr 'title-slide-transition'); if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" data-transition"); else; _buf << (" data-transition=\""); _buf << (_slim_codeattributes2); _buf << ("\""); end; end; _slim_codeattributes3 = (attr 'title-slide-transition-speed'); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" data-transition-speed"); else; _buf << (" data-transition-speed=\""); _buf << (_slim_codeattributes3); _buf << ("\""); end; end; _slim_codeattributes4 = (attr 'title-slide-background'); if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" data-background"); else; _buf << (" data-background=\""); _buf << (_slim_codeattributes4); _buf << ("\""); end; end; _slim_codeattributes5 = (attr 'title-slide-background-size'); if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" data-background-size"); else; _buf << (" data-background-size=\""); _buf << (_slim_codeattributes5); _buf << ("\""); end; end; _slim_codeattributes6 = bg_image; if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" data-background-image"); else; _buf << (" data-background-image=\""); _buf << (_slim_codeattributes6); _buf << ("\""); end; end; _slim_codeattributes7 = bg_video; if _slim_codeattributes7; if _slim_codeattributes7 == true; _buf << (" data-background-video"); else; _buf << (" data-background-video=\""); _buf << (_slim_codeattributes7); _buf << ("\""); end; end; _slim_codeattributes8 = (attr 'title-slide-background-video-loop'); if _slim_codeattributes8; if _slim_codeattributes8 == true; _buf << (" data-background-video-loop"); else; _buf << (" data-background-video-loop=\""); _buf << (_slim_codeattributes8); _buf << ("\""); end; end; _slim_codeattributes9 = (attr 'title-slide-background-video-muted'); if _slim_codeattributes9; if _slim_codeattributes9 == true; _buf << (" data-background-video-muted"); else; _buf << (" data-background-video-muted=\""); _buf << (_slim_codeattributes9); _buf << ("\""); end; end; _slim_codeattributes10 = (attr 'title-slide-background-opacity'); if _slim_codeattributes10; if _slim_codeattributes10 == true; _buf << (" data-background-opacity"); else; _buf << (" data-background-opacity=\""); _buf << (_slim_codeattributes10); _buf << ("\""); end; end; _slim_codeattributes11 = (attr 'title-slide-background-iframe'); if _slim_codeattributes11; if _slim_codeattributes11 == true; _buf << (" data-background-iframe"); else; _buf << (" data-background-iframe=\""); _buf << (_slim_codeattributes11); _buf << ("\""); end; end; _slim_codeattributes12 = (attr 'title-slide-background-color'); if _slim_codeattributes12; if _slim_codeattributes12 == true; _buf << (" data-background-color"); else; _buf << (" data-background-color=\""); _buf << (_slim_codeattributes12); _buf << ("\""); end; end; _slim_codeattributes13 = (attr 'title-slide-background-repeat'); if _slim_codeattributes13; if _slim_codeattributes13 == true; _buf << (" data-background-repeat"); else; _buf << (" data-background-repeat=\""); _buf << (_slim_codeattributes13); _buf << ("\""); end; end; _slim_codeattributes14 = (attr 'title-slide-background-position'); if _slim_codeattributes14; if _slim_codeattributes14 == true; _buf << (" data-background-position"); else; _buf << (" data-background-position=\""); _buf << (_slim_codeattributes14); _buf << ("\""); end; end; _slim_codeattributes15 = (attr 'title-slide-background-transition'); if _slim_codeattributes15; if _slim_codeattributes15 == true; _buf << (" data-background-transition"); else; _buf << (" data-background-transition=\""); _buf << (_slim_codeattributes15); _buf << ("\""); end; end; _buf << (">"); 
      ; if (_title_obj = doctitle partition: true, use_fallback: true).subtitle?; 
      ; _buf << ("<h1>"); _buf << (slice_text _title_obj.title, (_slice = header.option? :slice)); 
      ; _buf << ("</h1><h2>"); _buf << (slice_text _title_obj.subtitle, _slice); 
      ; _buf << ("</h2>"); else; 
      ; _buf << ("<h1>"); _buf << (@header.title); 
      ; _buf << ("</h1>"); end; preamble = @document.find_by context: :preamble; 
      ; unless preamble.nil? or preamble.length == 0; 
      ; _buf << ("<div class=\"preamble\">"); _buf << (preamble.pop.content); 
      ; _buf << ("</div>"); end; _buf << (generate_authors(@document)); 
      ; _buf << ("</section>"); _buf = _buf.join("")
    end
  end

  def convert_toc(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ("<div id=\"toc\""); _temple_html_attributeremover1 = []; _slim_codeattributes1 = (document.attr 'toc-class', 'toc'); if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes1.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes1); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _buf << ("><div id=\"toctitle\">"); 
      ; _buf << ((document.attr 'toc-title')); 
      ; _buf << ("</div>"); 
      ; _buf << (converter.convert document, 'outline'); 
      ; _buf << ("</div>"); _buf = _buf.join("")
    end
  end

  def convert_ulist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; if (checklist = (option? :checklist) ? 'checklist' : nil); 
      ; if option? :interactive; 
      ; marker_checked = '<input type="checkbox" data-item-complete="1" checked>'; 
      ; marker_unchecked = '<input type="checkbox" data-item-complete="0">'; 
      ; else; 
      ; if @document.attr? :icons, 'font'; 
      ; marker_checked = '<i class="icon-check"></i>'; 
      ; marker_unchecked = '<i class="icon-check-empty"></i>'; 
      ; else; 
      ; 
      ; marker_checked = '<input type="checkbox" data-item-complete="1" checked disabled>'; 
      ; marker_unchecked = '<input type="checkbox" data-item-complete="0" disabled>'; 
      ; end; end; end; _slim_controls1 = html_tag('div', { :id => @id, :class => ['ulist', checklist, @style, role] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (title); 
      ; _slim_controls2 << ("</div>"); end; _slim_controls2 << ("<ul"); _temple_html_attributeremover1 = []; _slim_codeattributes1 = (checklist || @style); if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes1.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes1); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover1); _slim_controls2 << ("\""); end; _slim_controls2 << (">"); 
      ; items.each do |item|; 
      ; _slim_controls2 << ("<li"); _temple_html_attributeremover2 = []; _slim_codeattributes2 = ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step')); if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover2 << (_slim_codeattributes2.join(" ")); else; _temple_html_attributeremover2 << (_slim_codeattributes2); end; _temple_html_attributeremover2 = _temple_html_attributeremover2.join(""); if !_temple_html_attributeremover2.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover2); _slim_controls2 << ("\""); end; _slim_controls2 << ("><p>"); 
      ; 
      ; if checklist && (item.attr? :checkbox); 
      ; _slim_controls2 << (%(#{(item.attr? :checked) ? marker_checked : marker_unchecked}#{item.text})); 
      ; else; 
      ; _slim_controls2 << (item.text); 
      ; end; _slim_controls2 << ("</p>"); if item.blocks?; 
      ; _slim_controls2 << (item.content); 
      ; end; _slim_controls2 << ("</li>"); end; _slim_controls2 << ("</ul>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def convert_verse(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; _slim_controls1 = html_tag('div', { :id => @id, :class => ['verseblock', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (title); 
      ; _slim_controls2 << ("</div>"); end; _slim_controls2 << ("<pre class=\"content\">"); _slim_controls2 << (content); 
      ; _slim_controls2 << ("</pre>"); attribution = (attr? :attribution) ? (attr :attribution) : nil; 
      ; citetitle = (attr? :citetitle) ? (attr :citetitle) : nil; 
      ; if attribution || citetitle; 
      ; _slim_controls2 << ("<div class=\"attribution\">"); 
      ; if citetitle; 
      ; _slim_controls2 << ("<cite>"); _slim_controls2 << (citetitle); 
      ; _slim_controls2 << ("</cite>"); end; if attribution; 
      ; if citetitle; 
      ; _slim_controls2 << ("<br>"); 
      ; end; _slim_controls2 << ("&#8212; "); _slim_controls2 << (attribution); 
      ; end; _slim_controls2 << ("</div>"); end; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def convert_video(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; 
      ; 
      ; no_stretch = ((attr? :width) || (attr? :height)); 
      ; width = (attr? :width) ? (attr :width) : "100%"; 
      ; height = (attr? :height) ? (attr :height) : "100%"; 
      ; 
      ; _slim_controls1 = html_tag('div', { :id => @id, :class => ['videoblock', @style, role, (no_stretch ? nil : 'stretch'), ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = []; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">"); _slim_controls2 << (captioned_title); 
      ; _slim_controls2 << ("</div>"); end; case attr :poster; 
      ; when 'vimeo'; 
      ; unless (asset_uri_scheme = (attr :asset_uri_scheme, 'https')).empty?; 
      ; asset_uri_scheme = %(#{asset_uri_scheme}:); 
      ; end; start_anchor = (attr? :start) ? "#at=#{attr :start}" : nil; 
      ; delimiter = ['?']; 
      ; loop_param = (option? 'loop') ? %(#{delimiter.pop || '&amp;'}loop=1) : ''; 
      ; muted_param = (option? 'muted') ? %(#{delimiter.pop || '&amp;'}muted=1) : ''; 
      ; src = %(#{asset_uri_scheme}//player.vimeo.com/video/#{attr :target}#{loop_param}#{muted_param}#{start_anchor}); 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _slim_controls2 << ("<iframe"); _slim_codeattributes1 = (width); if _slim_codeattributes1; if _slim_codeattributes1 == true; _slim_controls2 << (" width"); else; _slim_controls2 << (" width=\""); _slim_controls2 << (_slim_codeattributes1); _slim_controls2 << ("\""); end; end; _slim_codeattributes2 = (height); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls2 << (" height"); else; _slim_controls2 << (" height=\""); _slim_controls2 << (_slim_codeattributes2); _slim_controls2 << ("\""); end; end; _slim_codeattributes3 = src; if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" src"); else; _slim_controls2 << (" src=\""); _slim_controls2 << (_slim_codeattributes3); _slim_controls2 << ("\""); end; end; _slim_codeattributes4 = 0; if _slim_codeattributes4; if _slim_codeattributes4 == true; _slim_controls2 << (" frameborder"); else; _slim_controls2 << (" frameborder=\""); _slim_controls2 << (_slim_codeattributes4); _slim_controls2 << ("\""); end; end; _slim_controls2 << (" webkitAllowFullScreen mozallowfullscreen allowFullScreen"); _slim_codeattributes5 = (option? 'autoplay'); if _slim_codeattributes5; if _slim_codeattributes5 == true; _slim_controls2 << (" data-autoplay"); else; _slim_controls2 << (" data-autoplay=\""); _slim_controls2 << (_slim_codeattributes5); _slim_controls2 << ("\""); end; end; _slim_codeattributes6 = ((option? 'autoplay') ? "autoplay" : nil); if _slim_codeattributes6; if _slim_codeattributes6 == true; _slim_controls2 << (" allow"); else; _slim_controls2 << (" allow=\""); _slim_controls2 << (_slim_codeattributes6); _slim_controls2 << ("\""); end; end; _slim_controls2 << ("></iframe>"); 
      ; when 'youtube'; 
      ; unless (asset_uri_scheme = (attr :asset_uri_scheme, 'https')).empty?; 
      ; asset_uri_scheme = %(#{asset_uri_scheme}:); 
      ; end; params = ['rel=0']; 
      ; params << "start=#{attr :start}" if attr? :start; 
      ; params << "end=#{attr :end}" if attr? :end; 
      ; params << "loop=1" if option? 'loop'; 
      ; params << "mute=1" if option? 'muted'; 
      ; params << "controls=0" if option? 'nocontrols'; 
      ; src = %(#{asset_uri_scheme}//www.youtube.com/embed/#{attr :target}?#{params * '&amp;'}); 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _slim_controls2 << ("<iframe"); _slim_codeattributes7 = (width); if _slim_codeattributes7; if _slim_codeattributes7 == true; _slim_controls2 << (" width"); else; _slim_controls2 << (" width=\""); _slim_controls2 << (_slim_codeattributes7); _slim_controls2 << ("\""); end; end; _slim_codeattributes8 = (height); if _slim_codeattributes8; if _slim_codeattributes8 == true; _slim_controls2 << (" height"); else; _slim_controls2 << (" height=\""); _slim_controls2 << (_slim_codeattributes8); _slim_controls2 << ("\""); end; end; _slim_codeattributes9 = src; if _slim_codeattributes9; if _slim_codeattributes9 == true; _slim_controls2 << (" src"); else; _slim_controls2 << (" src=\""); _slim_controls2 << (_slim_codeattributes9); _slim_controls2 << ("\""); end; end; _slim_codeattributes10 = 0; if _slim_codeattributes10; if _slim_codeattributes10 == true; _slim_controls2 << (" frameborder"); else; _slim_controls2 << (" frameborder=\""); _slim_controls2 << (_slim_codeattributes10); _slim_controls2 << ("\""); end; end; _slim_codeattributes11 = !(option? 'nofullscreen'); if _slim_codeattributes11; if _slim_codeattributes11 == true; _slim_controls2 << (" allowfullscreen"); else; _slim_controls2 << (" allowfullscreen=\""); _slim_controls2 << (_slim_codeattributes11); _slim_controls2 << ("\""); end; end; _slim_codeattributes12 = (option? 'autoplay'); if _slim_codeattributes12; if _slim_codeattributes12 == true; _slim_controls2 << (" data-autoplay"); else; _slim_controls2 << (" data-autoplay=\""); _slim_controls2 << (_slim_codeattributes12); _slim_controls2 << ("\""); end; end; _slim_codeattributes13 = ((option? 'autoplay') ? "autoplay" : nil); if _slim_codeattributes13; if _slim_codeattributes13 == true; _slim_controls2 << (" allow"); else; _slim_controls2 << (" allow=\""); _slim_controls2 << (_slim_codeattributes13); _slim_controls2 << ("\""); end; end; _slim_controls2 << ("></iframe>"); 
      ; else; 
      ; 
      ; 
      ; 
      ; _slim_controls2 << ("<video"); _slim_codeattributes14 = media_uri(attr :target); if _slim_codeattributes14; if _slim_codeattributes14 == true; _slim_controls2 << (" src"); else; _slim_controls2 << (" src=\""); _slim_controls2 << (_slim_codeattributes14); _slim_controls2 << ("\""); end; end; _slim_codeattributes15 = (width); if _slim_codeattributes15; if _slim_codeattributes15 == true; _slim_controls2 << (" width"); else; _slim_controls2 << (" width=\""); _slim_controls2 << (_slim_codeattributes15); _slim_controls2 << ("\""); end; end; _slim_codeattributes16 = (height); if _slim_codeattributes16; if _slim_codeattributes16 == true; _slim_controls2 << (" height"); else; _slim_controls2 << (" height=\""); _slim_controls2 << (_slim_codeattributes16); _slim_controls2 << ("\""); end; end; _slim_codeattributes17 = ((attr :poster) ? media_uri(attr :poster) : nil); if _slim_codeattributes17; if _slim_codeattributes17 == true; _slim_controls2 << (" poster"); else; _slim_controls2 << (" poster=\""); _slim_controls2 << (_slim_codeattributes17); _slim_controls2 << ("\""); end; end; _slim_codeattributes18 = (option? 'autoplay'); if _slim_codeattributes18; if _slim_codeattributes18 == true; _slim_controls2 << (" data-autoplay"); else; _slim_controls2 << (" data-autoplay=\""); _slim_controls2 << (_slim_codeattributes18); _slim_controls2 << ("\""); end; end; _slim_codeattributes19 = !(option? 'nocontrols'); if _slim_codeattributes19; if _slim_codeattributes19 == true; _slim_controls2 << (" controls"); else; _slim_controls2 << (" controls=\""); _slim_controls2 << (_slim_codeattributes19); _slim_controls2 << ("\""); end; end; _slim_codeattributes20 = (option? 'loop'); if _slim_codeattributes20; if _slim_codeattributes20 == true; _slim_controls2 << (" loop"); else; _slim_controls2 << (" loop=\""); _slim_controls2 << (_slim_codeattributes20); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">Your browser does not support the video tag.</video>"); 
      ; 
      ; end; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def convert_section(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = []; 
      ; 
      ; titleless = (title = self.title) == '!'; 
      ; hide_title = (titleless || (option? :notitle) || (option? :conceal)); 
      ; 
      ; vertical_slides = find_by(context: :section) {|section| section.level == 2 }; 
      ; 
      ; 
      ; 
      ; data_background_image, data_background_size, data_background_repeat,
      data_background_position, data_background_transition = nil; 
      ; 
      ; 
      ; section_images = blocks.map do |block|; 
      ; if (ctx = block.context) == :image; 
      ; ['background', 'canvas'].include?(block.attributes[1]) ? block : []; 
      ; elsif ctx == :section; 
      ; []; 
      ; else; 
      ; block.find_by(context: :image) {|image| ['background', 'canvas'].include?(image.attributes[1]) } || []; 
      ; end; end; if (bg_image = section_images.flatten.first); 
      ; data_background_image = image_uri(bg_image.attr 'target'); 
      ; 
      ; data_background_size = bg_image.attr 'size'; 
      ; data_background_repeat = bg_image.attr 'repeat'; 
      ; data_background_transition = bg_image.attr 'transition'; 
      ; data_background_position = bg_image.attr 'position'; 
      ; 
      ; 
      ; end; if attr? 'background-image'; 
      ; data_background_image = image_uri(attr 'background-image'); 
      ; 
      ; end; if attr? 'background-video'; 
      ; data_background_video = media_uri(attr 'background-video'); 
      ; 
      ; end; if attr? 'background-color'; 
      ; data_background_color = attr 'background-color'; 
      ; 
      ; end; parent_section_with_vertical_slides = @level == 1 && !vertical_slides.empty?; 
      ; 
      ; content_for :footnotes do; 
      ; slide_footnotes = slide_footnotes(self); 
      ; if document.footnotes? && !(parent.attr? 'nofootnotes') && !slide_footnotes.empty?; 
      ; _buf << ("<div class=\"footnotes\">"); 
      ; slide_footnotes.each do |footnote|; 
      ; _buf << ("<div class=\"footnote\">"); 
      ; _buf << ("#{footnote.index}. #{footnote.text}"); 
      ; 
      ; _buf << ("</div>"); end; _buf << ("</div>"); end; end; content_for :section do; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ("<section"); _slim_codeattributes1 = (titleless ? nil : id); if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes1); _buf << ("\""); end; end; _temple_html_attributeremover1 = []; _slim_codeattributes2 = roles; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes2.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes2); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _slim_codeattributes3 = (attr "background-gradient"); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" data-background-gradient"); else; _buf << (" data-background-gradient=\""); _buf << (_slim_codeattributes3); _buf << ("\""); end; end; _slim_codeattributes4 = (attr 'transition'); if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" data-transition"); else; _buf << (" data-transition=\""); _buf << (_slim_codeattributes4); _buf << ("\""); end; end; _slim_codeattributes5 = (attr 'transition-speed'); if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" data-transition-speed"); else; _buf << (" data-transition-speed=\""); _buf << (_slim_codeattributes5); _buf << ("\""); end; end; _slim_codeattributes6 = data_background_color; if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" data-background-color"); else; _buf << (" data-background-color=\""); _buf << (_slim_codeattributes6); _buf << ("\""); end; end; _slim_codeattributes7 = data_background_image; if _slim_codeattributes7; if _slim_codeattributes7 == true; _buf << (" data-background-image"); else; _buf << (" data-background-image=\""); _buf << (_slim_codeattributes7); _buf << ("\""); end; end; _slim_codeattributes8 = (data_background_size || attr('background-size')); if _slim_codeattributes8; if _slim_codeattributes8 == true; _buf << (" data-background-size"); else; _buf << (" data-background-size=\""); _buf << (_slim_codeattributes8); _buf << ("\""); end; end; _slim_codeattributes9 = (data_background_repeat || attr('background-repeat')); if _slim_codeattributes9; if _slim_codeattributes9 == true; _buf << (" data-background-repeat"); else; _buf << (" data-background-repeat=\""); _buf << (_slim_codeattributes9); _buf << ("\""); end; end; _slim_codeattributes10 = (data_background_transition || attr('background-transition')); if _slim_codeattributes10; if _slim_codeattributes10 == true; _buf << (" data-background-transition"); else; _buf << (" data-background-transition=\""); _buf << (_slim_codeattributes10); _buf << ("\""); end; end; _slim_codeattributes11 = (data_background_position || attr('background-position')); if _slim_codeattributes11; if _slim_codeattributes11 == true; _buf << (" data-background-position"); else; _buf << (" data-background-position=\""); _buf << (_slim_codeattributes11); _buf << ("\""); end; end; _slim_codeattributes12 = (attr "background-iframe"); if _slim_codeattributes12; if _slim_codeattributes12 == true; _buf << (" data-background-iframe"); else; _buf << (" data-background-iframe=\""); _buf << (_slim_codeattributes12); _buf << ("\""); end; end; _slim_codeattributes13 = data_background_video; if _slim_codeattributes13; if _slim_codeattributes13 == true; _buf << (" data-background-video"); else; _buf << (" data-background-video=\""); _buf << (_slim_codeattributes13); _buf << ("\""); end; end; _slim_codeattributes14 = ((attr? 'background-video-loop') || (option? 'loop')); if _slim_codeattributes14; if _slim_codeattributes14 == true; _buf << (" data-background-video-loop"); else; _buf << (" data-background-video-loop=\""); _buf << (_slim_codeattributes14); _buf << ("\""); end; end; _slim_codeattributes15 = ((attr? 'background-video-muted') || (option? 'muted')); if _slim_codeattributes15; if _slim_codeattributes15 == true; _buf << (" data-background-video-muted"); else; _buf << (" data-background-video-muted=\""); _buf << (_slim_codeattributes15); _buf << ("\""); end; end; _slim_codeattributes16 = (attr "background-opacity"); if _slim_codeattributes16; if _slim_codeattributes16 == true; _buf << (" data-background-opacity"); else; _buf << (" data-background-opacity=\""); _buf << (_slim_codeattributes16); _buf << ("\""); end; end; _slim_codeattributes17 = (attr "autoslide"); if _slim_codeattributes17; if _slim_codeattributes17 == true; _buf << (" data-autoslide"); else; _buf << (" data-autoslide=\""); _buf << (_slim_codeattributes17); _buf << ("\""); end; end; _slim_codeattributes18 = (attr 'state'); if _slim_codeattributes18; if _slim_codeattributes18 == true; _buf << (" data-state"); else; _buf << (" data-state=\""); _buf << (_slim_codeattributes18); _buf << ("\""); end; end; _slim_codeattributes19 = ((attr? 'auto-animate') || (option? 'auto-animate')); if _slim_codeattributes19; if _slim_codeattributes19 == true; _buf << (" data-auto-animate"); else; _buf << (" data-auto-animate=\""); _buf << (_slim_codeattributes19); _buf << ("\""); end; end; _slim_codeattributes20 = ((attr 'auto-animate-easing') || (option? 'auto-animate-easing')); if _slim_codeattributes20; if _slim_codeattributes20 == true; _buf << (" data-auto-animate-easing"); else; _buf << (" data-auto-animate-easing=\""); _buf << (_slim_codeattributes20); _buf << ("\""); end; end; _slim_codeattributes21 = ((attr 'auto-animate-unmatched') || (option? 'auto-animate-unmatched')); if _slim_codeattributes21; if _slim_codeattributes21 == true; _buf << (" data-auto-animate-unmatched"); else; _buf << (" data-auto-animate-unmatched=\""); _buf << (_slim_codeattributes21); _buf << ("\""); end; end; _slim_codeattributes22 = ((attr 'auto-animate-duration') || (option? 'auto-animate-duration')); if _slim_codeattributes22; if _slim_codeattributes22 == true; _buf << (" data-auto-animate-duration"); else; _buf << (" data-auto-animate-duration=\""); _buf << (_slim_codeattributes22); _buf << ("\""); end; end; _slim_codeattributes23 = (attr 'auto-animate-id'); if _slim_codeattributes23; if _slim_codeattributes23 == true; _buf << (" data-auto-animate-id"); else; _buf << (" data-auto-animate-id=\""); _buf << (_slim_codeattributes23); _buf << ("\""); end; end; _slim_codeattributes24 = ((attr? 'auto-animate-restart') || (option? 'auto-animate-restart')); if _slim_codeattributes24; if _slim_codeattributes24 == true; _buf << (" data-auto-animate-restart"); else; _buf << (" data-auto-animate-restart=\""); _buf << (_slim_codeattributes24); _buf << ("\""); end; end; _buf << (">"); 
      ; unless hide_title; 
      ; _buf << ("<h2>"); _buf << (section_title); 
      ; _buf << ("</h2>"); end; if parent_section_with_vertical_slides; 
      ; unless (_blocks = blocks - vertical_slides).empty?; 
      ; _buf << ("<div class=\"slide-content\">"); 
      ; _blocks.each do |block|; 
      ; _buf << (block.convert); 
      ; end; _buf << ("</div>"); end; yield_content :footnotes; 
      ; 
      ; else; 
      ; unless (_content = content.chomp).empty?; 
      ; _buf << ("<div class=\"slide-content\">"); 
      ; _buf << (_content); 
      ; _buf << ("</div>"); end; yield_content :footnotes; 
      ; 
      ; end; clear_slide_footnotes; 
      ; 
      ; _buf << ("</section>"); 
      ; 
      ; end; if parent_section_with_vertical_slides; 
      ; _buf << ("<section>"); 
      ; yield_content :section; 
      ; vertical_slides.each do |subsection|; 
      ; _buf << (subsection.convert); 
      ; 
      ; end; _buf << ("</section>"); 
      ; else; 
      ; if @level >= 3; 
      ; 
      ; _slim_htag_filter1 = ((@level)).to_s; _buf << ("<h"); _buf << (_slim_htag_filter1); _buf << (">"); _buf << (title); 
      ; _buf << ("</h"); _buf << (_slim_htag_filter1); _buf << (">"); _buf << (content.chomp); 
      ; else; 
      ; yield_content :section; 
      ; end; end; _buf = _buf.join("")
    end
  end
  #------------------ End of generated transformation methods ------------------#

  def set_local_variables(binding, vars)
    vars.each do |key, val|
      binding.local_variable_set(key.to_sym, val)
    end
  end

end
