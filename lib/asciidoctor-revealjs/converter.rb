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


  def convert_notes(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<aside class=\"notes\">".freeze); _buf << ((resolve_content).to_s); 
      ; _buf << ("</aside>".freeze); _buf
    end
  end

  def convert_inline_anchor(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; case @type; 
      ; when :xref; 
      ; refid = (attr :refid) || @target; 
      ; _slim_controls1 = html_tag('a', { :href => @target, :class => [role, ('fragment' if (option? :step) || (attr? 'step'))].compact }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; _slim_controls2 << (((@text || @document.references[:ids].fetch(refid, "[#{refid}]")).tr_s("\n", ' ')).to_s); 
      ; _slim_controls2; end; _buf << ((_slim_controls1).to_s); when :ref; 
      ; _buf << ((html_tag('a', { :id => @target }.merge(data_attrs(@attributes)))).to_s); 
      ; when :bibref; 
      ; _buf << ((html_tag('a', { :id => @target }.merge(data_attrs(@attributes)))).to_s); 
      ; _buf << ("[".freeze); _buf << ((@target).to_s); _buf << ("]".freeze); 
      ; else; 
      ; _slim_controls3 = html_tag('a', { :href => @target, :class => [role, ('fragment' if (option? :step) || (attr? 'step'))].compact, :target => (attr :window), 'data-preview-link' => (bool_data_attr :preview) }.merge(data_attrs(@attributes))) do; _slim_controls4 = ''; 
      ; _slim_controls4 << ((@text).to_s); 
      ; _slim_controls4; end; _buf << ((_slim_controls3).to_s); end; _buf
    end
  end

  def convert_ruler(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<hr>".freeze); 
      ; _buf
    end
  end

  def convert_stem(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; open, close = Asciidoctor::BLOCK_MATH_DELIMITERS[@style.to_sym]; 
      ; equation = content.strip; 
      ; if (@subs.nil? || @subs.empty?) && !(attr? 'subs'); 
      ; equation = sub_specialcharacters equation; 
      ; end; unless (equation.start_with? open) && (equation.end_with? close); 
      ; equation = %(#{open}#{equation}#{close}); 
      ; end; _slim_controls1 = html_tag('div', { :id => @id, :class => ['stemblock', role, ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; _slim_controls2 << ("<div class=\"content\">".freeze); _slim_controls2 << ((equation).to_s); 
      ; _slim_controls2 << ("</div>".freeze); _slim_controls2; end; _buf << ((_slim_controls1).to_s); _buf
    end
  end

  def convert_embedded(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; unless notitle || !has_header?; 
      ; _buf << ("<h1".freeze); _slim_codeattributes1 = @id; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes1).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); _buf << ((@header.title).to_s); 
      ; _buf << ("</h1>".freeze); end; _buf << ((content).to_s); 
      ; unless !footnotes? || attr?(:nofootnotes); 
      ; _buf << ("<div id=\"footnotes\"><hr>".freeze); 
      ; 
      ; footnotes.each do |fn|; 
      ; _buf << ("<div class=\"footnote\" id=\"_footnote_".freeze); _buf << ((fn.index).to_s); _buf << ("\"><a href=\"#_footnoteref_".freeze); 
      ; _buf << ((fn.index).to_s); _buf << ("\">".freeze); _buf << ((fn.index).to_s); _buf << ("</a>. ".freeze); _buf << ((fn.text).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ("</div>".freeze); end; _buf
    end
  end

  def convert_ulist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; if (checklist = (option? :checklist) ? 'checklist' : nil); 
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
      ; end; end; end; _slim_controls1 = html_tag('div', { :id => @id, :class => ['ulist', checklist, @style, role] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; _slim_controls2 << ("<ul".freeze); _temple_html_attributeremover1 = ''; _slim_codeattributes1 = (checklist || @style); if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes1).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\"".freeze); _slim_controls2 << ((_temple_html_attributeremover1).to_s); _slim_controls2 << ("\"".freeze); end; _slim_controls2 << (">".freeze); 
      ; items.each do |item|; 
      ; _slim_controls2 << ("<li".freeze); _temple_html_attributeremover2 = ''; _slim_codeattributes2 = ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step')); if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover2 << ((_slim_codeattributes2.join(" ")).to_s); else; _temple_html_attributeremover2 << ((_slim_codeattributes2).to_s); end; _temple_html_attributeremover2; if !_temple_html_attributeremover2.empty?; _slim_controls2 << (" class=\"".freeze); _slim_controls2 << ((_temple_html_attributeremover2).to_s); _slim_controls2 << ("\"".freeze); end; _slim_controls2 << ("><p>".freeze); 
      ; 
      ; if checklist && (item.attr? :checkbox); 
      ; _slim_controls2 << ((%(#{(item.attr? :checked) ? marker_checked : marker_unchecked}#{item.text})).to_s); 
      ; else; 
      ; _slim_controls2 << ((item.text).to_s); 
      ; end; _slim_controls2 << ("</p>".freeze); if item.blocks?; 
      ; _slim_controls2 << ((item.content).to_s); 
      ; end; _slim_controls2 << ("</li>".freeze); end; _slim_controls2 << ("</ul>".freeze); _slim_controls2; end; _buf << ((_slim_controls1).to_s); _buf
    end
  end

  def convert_paragraph(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _slim_controls1 = html_tag('div', { :id => @id, :class => ['paragraph', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; if has_role? 'small'; 
      ; _slim_controls2 << ("<small>".freeze); _slim_controls2 << ((content).to_s); 
      ; _slim_controls2 << ("</small>".freeze); else; 
      ; _slim_controls2 << ("<p>".freeze); _slim_controls2 << ((content).to_s); 
      ; _slim_controls2 << ("</p>".freeze); end; _slim_controls2; end; _buf << ((_slim_controls1).to_s); _buf
    end
  end

  def convert_dlist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; case @style; 
      ; when 'qanda'; 
      ; _slim_controls1 = html_tag('div', { :id => @id, :class => ['qlist', @style, role] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; _slim_controls2 << ("<ol>".freeze); 
      ; items.each do |questions, answer|; 
      ; _slim_controls2 << ("<li>".freeze); 
      ; [*questions].each do |question|; 
      ; _slim_controls2 << ("<p><em>".freeze); _slim_controls2 << ((question.text).to_s); 
      ; _slim_controls2 << ("</em></p>".freeze); end; unless answer.nil?; 
      ; if answer.text?; 
      ; _slim_controls2 << ("<p>".freeze); _slim_controls2 << ((answer.text).to_s); 
      ; _slim_controls2 << ("</p>".freeze); end; if answer.blocks?; 
      ; _slim_controls2 << ((answer.content).to_s); 
      ; end; end; _slim_controls2 << ("</li>".freeze); end; _slim_controls2 << ("</ol>".freeze); _slim_controls2; end; _buf << ((_slim_controls1).to_s); when 'horizontal'; 
      ; _slim_controls3 = html_tag('div', { :id => @id, :class => ['hdlist', role] }.merge(data_attrs(@attributes))) do; _slim_controls4 = ''; 
      ; if title?; 
      ; _slim_controls4 << ("<div class=\"title\">".freeze); _slim_controls4 << ((title).to_s); 
      ; _slim_controls4 << ("</div>".freeze); end; _slim_controls4 << ("<table>".freeze); 
      ; if (attr? :labelwidth) || (attr? :itemwidth); 
      ; _slim_controls4 << ("<colgroup><col".freeze); 
      ; _slim_codeattributes1 = ((attr? :labelwidth) ? %(width:#{(attr :labelwidth).chomp '%'}%;) : nil); if _slim_codeattributes1; if _slim_codeattributes1 == true; _slim_controls4 << (" style".freeze); else; _slim_controls4 << (" style=\"".freeze); _slim_controls4 << ((_slim_codeattributes1).to_s); _slim_controls4 << ("\"".freeze); end; end; _slim_controls4 << ("><col".freeze); 
      ; _slim_codeattributes2 = ((attr? :itemwidth) ? %(width:#{(attr :itemwidth).chomp '%'}%;) : nil); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls4 << (" style".freeze); else; _slim_controls4 << (" style=\"".freeze); _slim_controls4 << ((_slim_codeattributes2).to_s); _slim_controls4 << ("\"".freeze); end; end; _slim_controls4 << ("></colgroup>".freeze); 
      ; end; items.each do |terms, dd|; 
      ; _slim_controls4 << ("<tr><td".freeze); 
      ; _temple_html_attributeremover1 = ''; _slim_codeattributes3 = ['hdlist1',('strong' if option? 'strong')]; if Array === _slim_codeattributes3; _slim_codeattributes3 = _slim_codeattributes3.flatten; _slim_codeattributes3.map!(&:to_s); _slim_codeattributes3.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes3.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes3).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _slim_controls4 << (" class=\"".freeze); _slim_controls4 << ((_temple_html_attributeremover1).to_s); _slim_controls4 << ("\"".freeze); end; _slim_controls4 << (">".freeze); 
      ; terms = [*terms]; 
      ; last_term = terms.last; 
      ; terms.each do |dt|; 
      ; _slim_controls4 << ((dt.text).to_s); 
      ; if dt != last_term; 
      ; _slim_controls4 << ("<br>".freeze); 
      ; end; end; _slim_controls4 << ("</td><td class=\"hdlist2\">".freeze); 
      ; unless dd.nil?; 
      ; if dd.text?; 
      ; _slim_controls4 << ("<p>".freeze); _slim_controls4 << ((dd.text).to_s); 
      ; _slim_controls4 << ("</p>".freeze); end; if dd.blocks?; 
      ; _slim_controls4 << ((dd.content).to_s); 
      ; end; end; _slim_controls4 << ("</td></tr>".freeze); end; _slim_controls4 << ("</table>".freeze); _slim_controls4; end; _buf << ((_slim_controls3).to_s); else; 
      ; _slim_controls5 = html_tag('div', { :id => @id, :class => ['dlist', @style, role] }.merge(data_attrs(@attributes))) do; _slim_controls6 = ''; 
      ; if title?; 
      ; _slim_controls6 << ("<div class=\"title\">".freeze); _slim_controls6 << ((title).to_s); 
      ; _slim_controls6 << ("</div>".freeze); end; _slim_controls6 << ("<dl>".freeze); 
      ; items.each do |terms, dd|; 
      ; [*terms].each do |dt|; 
      ; _slim_controls6 << ("<dt".freeze); _temple_html_attributeremover2 = ''; _slim_codeattributes4 = ('hdlist1' unless @style); if Array === _slim_codeattributes4; _slim_codeattributes4 = _slim_codeattributes4.flatten; _slim_codeattributes4.map!(&:to_s); _slim_codeattributes4.reject!(&:empty?); _temple_html_attributeremover2 << ((_slim_codeattributes4.join(" ")).to_s); else; _temple_html_attributeremover2 << ((_slim_codeattributes4).to_s); end; _temple_html_attributeremover2; if !_temple_html_attributeremover2.empty?; _slim_controls6 << (" class=\"".freeze); _slim_controls6 << ((_temple_html_attributeremover2).to_s); _slim_controls6 << ("\"".freeze); end; _slim_controls6 << (">".freeze); _slim_controls6 << ((dt.text).to_s); 
      ; _slim_controls6 << ("</dt>".freeze); end; unless dd.nil?; 
      ; _slim_controls6 << ("<dd>".freeze); 
      ; if dd.text?; 
      ; _slim_controls6 << ("<p>".freeze); _slim_controls6 << ((dd.text).to_s); 
      ; _slim_controls6 << ("</p>".freeze); end; if dd.blocks?; 
      ; _slim_controls6 << ((dd.content).to_s); 
      ; end; _slim_controls6 << ("</dd>".freeze); end; end; _slim_controls6 << ("</dl>".freeze); _slim_controls6; end; _buf << ((_slim_controls5).to_s); end; _buf
    end
  end

  def convert_audio(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _slim_controls1 = html_tag('div', { :id => @id, :class => ['audioblock', @style, role] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((captioned_title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; _slim_controls2 << ("<div class=\"content\"><audio".freeze); 
      ; _slim_codeattributes1 = media_uri(attr :target); if _slim_codeattributes1; if _slim_codeattributes1 == true; _slim_controls2 << (" src".freeze); else; _slim_controls2 << (" src=\"".freeze); _slim_controls2 << ((_slim_codeattributes1).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes2 = (option? 'autoplay'); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls2 << (" autoplay".freeze); else; _slim_controls2 << (" autoplay=\"".freeze); _slim_controls2 << ((_slim_codeattributes2).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes3 = !(option? 'nocontrols'); if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" controls".freeze); else; _slim_controls2 << (" controls=\"".freeze); _slim_controls2 << ((_slim_codeattributes3).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes4 = (option? 'loop'); if _slim_codeattributes4; if _slim_codeattributes4 == true; _slim_controls2 << (" loop".freeze); else; _slim_controls2 << (" loop=\"".freeze); _slim_controls2 << ((_slim_codeattributes4).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_controls2 << (">Your browser does not support the audio tag.</audio></div>".freeze); 
      ; 
      ; _slim_controls2; end; _buf << ((_slim_controls1).to_s); _buf
    end
  end

  def convert_image(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; unless attributes[1] == 'background' || attributes[1] == 'canvas'; 
      ; inline_style = [("text-align: #{attr :align}" if attr? :align),("float: #{attr :float}" if attr? :float)].compact.join('; '); 
      ; _slim_controls1 = html_tag('div', { :id => @id, :class => ['imageblock', role, ('fragment' if (option? :step) || (attr? 'step'))], :style => inline_style }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; _slim_controls2 << ((convert_image).to_s); 
      ; _slim_controls2; end; _buf << ((_slim_controls1).to_s); if title?; 
      ; _buf << ("<div class=\"title\">".freeze); _buf << ((captioned_title).to_s); 
      ; _buf << ("</div>".freeze); end; end; _buf
    end
  end

  def convert_toc(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; 
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
      ; _buf << ("<div id=\"toc\"".freeze); _temple_html_attributeremover1 = ''; _slim_codeattributes1 = (document.attr 'toc-class', 'toc'); if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes1).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _buf << ("><div id=\"toctitle\">".freeze); 
      ; _buf << (((document.attr 'toc-title')).to_s); 
      ; _buf << ("</div>".freeze); 
      ; _buf << ((converter.convert document, 'outline').to_s); 
      ; _buf << ("</div>".freeze); _buf
    end
  end

  def convert_inline_kbd(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; if (keys = attr 'keys').size == 1; 
      ; _slim_controls1 = html_tag('kbd', data_attrs(@attributes)) do; _slim_controls2 = ''; 
      ; _slim_controls2 << ((keys.first).to_s); 
      ; _slim_controls2; end; _buf << ((_slim_controls1).to_s); else; 
      ; _slim_controls3 = html_tag('span', { :class => ['keyseq'] }.merge(data_attrs(@attributes))) do; _slim_controls4 = ''; 
      ; keys.each_with_index do |key, idx|; 
      ; unless idx.zero?; 
      ; _slim_controls4 << ("+".freeze); 
      ; end; _slim_controls4 << ("<kbd>".freeze); _slim_controls4 << ((key).to_s); 
      ; _slim_controls4 << ("</kbd>".freeze); end; _slim_controls4; end; _buf << ((_slim_controls3).to_s); end; _buf
    end
  end

  def convert_title_slide(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; bg_image = (attr? 'title-slide-background-image') ? (image_uri(attr 'title-slide-background-image')) : nil; 
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
      ; _buf << ("<section".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "title"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = role; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _buf << (" data-state=\"title\"".freeze); _slim_codeattributes2 = (attr 'title-slide-transition'); if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" data-transition".freeze); else; _buf << (" data-transition=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes3 = (attr 'title-slide-transition-speed'); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" data-transition-speed".freeze); else; _buf << (" data-transition-speed=\"".freeze); _buf << ((_slim_codeattributes3).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes4 = (attr 'title-slide-background'); if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" data-background".freeze); else; _buf << (" data-background=\"".freeze); _buf << ((_slim_codeattributes4).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes5 = (attr 'title-slide-background-size'); if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" data-background-size".freeze); else; _buf << (" data-background-size=\"".freeze); _buf << ((_slim_codeattributes5).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes6 = bg_image; if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" data-background-image".freeze); else; _buf << (" data-background-image=\"".freeze); _buf << ((_slim_codeattributes6).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes7 = bg_video; if _slim_codeattributes7; if _slim_codeattributes7 == true; _buf << (" data-background-video".freeze); else; _buf << (" data-background-video=\"".freeze); _buf << ((_slim_codeattributes7).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes8 = (attr 'title-slide-background-video-loop'); if _slim_codeattributes8; if _slim_codeattributes8 == true; _buf << (" data-background-video-loop".freeze); else; _buf << (" data-background-video-loop=\"".freeze); _buf << ((_slim_codeattributes8).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes9 = (attr 'title-slide-background-video-muted'); if _slim_codeattributes9; if _slim_codeattributes9 == true; _buf << (" data-background-video-muted".freeze); else; _buf << (" data-background-video-muted=\"".freeze); _buf << ((_slim_codeattributes9).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes10 = (attr 'title-slide-background-opacity'); if _slim_codeattributes10; if _slim_codeattributes10 == true; _buf << (" data-background-opacity".freeze); else; _buf << (" data-background-opacity=\"".freeze); _buf << ((_slim_codeattributes10).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes11 = (attr 'title-slide-background-iframe'); if _slim_codeattributes11; if _slim_codeattributes11 == true; _buf << (" data-background-iframe".freeze); else; _buf << (" data-background-iframe=\"".freeze); _buf << ((_slim_codeattributes11).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes12 = (attr 'title-slide-background-color'); if _slim_codeattributes12; if _slim_codeattributes12 == true; _buf << (" data-background-color".freeze); else; _buf << (" data-background-color=\"".freeze); _buf << ((_slim_codeattributes12).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes13 = (attr 'title-slide-background-repeat'); if _slim_codeattributes13; if _slim_codeattributes13 == true; _buf << (" data-background-repeat".freeze); else; _buf << (" data-background-repeat=\"".freeze); _buf << ((_slim_codeattributes13).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes14 = (attr 'title-slide-background-position'); if _slim_codeattributes14; if _slim_codeattributes14 == true; _buf << (" data-background-position".freeze); else; _buf << (" data-background-position=\"".freeze); _buf << ((_slim_codeattributes14).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes15 = (attr 'title-slide-background-transition'); if _slim_codeattributes15; if _slim_codeattributes15 == true; _buf << (" data-background-transition".freeze); else; _buf << (" data-background-transition=\"".freeze); _buf << ((_slim_codeattributes15).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if (_title_obj = doctitle partition: true, use_fallback: true).subtitle?; 
      ; _buf << ("<h1>".freeze); _buf << ((slice_text _title_obj.title, (_slice = header.option? :slice)).to_s); 
      ; _buf << ("</h1><h2>".freeze); _buf << ((slice_text _title_obj.subtitle, _slice).to_s); 
      ; _buf << ("</h2>".freeze); else; 
      ; _buf << ("<h1>".freeze); _buf << ((@header.title).to_s); 
      ; _buf << ("</h1>".freeze); end; preamble = @document.find_by context: :preamble; 
      ; unless preamble.nil? or preamble.length == 0; 
      ; _buf << ("<div class=\"preamble\">".freeze); _buf << ((preamble.pop.content).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ((generate_authors(@document)).to_s); 
      ; _buf << ("</section>".freeze); _buf
    end
  end

  def convert_inline_quoted(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; quote_tags = { emphasis: 'em', strong: 'strong', monospaced: 'code', superscript: 'sup', subscript: 'sub' }; 
      ; if (quote_tag = quote_tags[@type]); 
      ; _buf << ((html_tag(quote_tag, { :id => @id, :class => [role, ('fragment' if (option? :step) || (attr? 'step'))].compact }.merge(data_attrs(@attributes)), @text)).to_s); 
      ; else; 
      ; case @type; 
      ; when :double; 
      ; _buf << ((inline_text_container("&#8220;#{@text}&#8221;")).to_s); 
      ; when :single; 
      ; _buf << ((inline_text_container("&#8216;#{@text}&#8217;")).to_s); 
      ; when :asciimath, :latexmath; 
      ; open, close = Asciidoctor::INLINE_MATH_DELIMITERS[@type]; 
      ; _buf << ((inline_text_container("#{open}#{@text}#{close}")).to_s); 
      ; else; 
      ; _buf << ((inline_text_container(@text)).to_s); 
      ; end; end; _buf
    end
  end

  def convert_inline_callout(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; if @document.attr? :icons, 'font'; 
      ; _buf << ("<i class=\"conum\"".freeze); _slim_codeattributes1 = @text; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" data-value".freeze); else; _buf << (" data-value=\"".freeze); _buf << ((_slim_codeattributes1).to_s); _buf << ("\"".freeze); end; end; _buf << ("></i><b>".freeze); 
      ; _buf << (("(#{@text})").to_s); 
      ; _buf << ("</b>".freeze); elsif @document.attr? :icons; 
      ; _buf << ("<img".freeze); _slim_codeattributes2 = icon_uri("callouts/#{@text}"); if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" src".freeze); else; _buf << (" src=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes3 = @text; if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" alt".freeze); else; _buf << (" alt=\"".freeze); _buf << ((_slim_codeattributes3).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; else; 
      ; _buf << ("<b>".freeze); _buf << (("(#{@text})").to_s); 
      ; _buf << ("</b>".freeze); end; _buf
    end
  end

  def convert_floating_title(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _slim_htag_filter1 = ((level + 1)).to_s; _buf << ("<h".freeze); _buf << ((_slim_htag_filter1).to_s); _slim_codeattributes1 = id; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes1).to_s); _buf << ("\"".freeze); end; end; _temple_html_attributeremover1 = ''; _slim_codeattributes2 = [style, role]; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes2.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes2).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _buf << (">".freeze); 
      ; _buf << ((title).to_s); 
      ; _buf << ("</h".freeze); _buf << ((_slim_htag_filter1).to_s); _buf << (">".freeze); _buf
    end
  end

  def convert_table(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; classes = ['tableblock', "frame-#{attr :frame, 'all'}", "grid-#{attr :grid, 'all'}", role, ('fragment' if (option? :step) || (attr? 'step'))]; 
      ; styles = [("width:#{attr :tablepcwidth}%" unless option? 'autowidth'), ("float:#{attr :float}" if attr? :float)].compact.join('; '); 
      ; _slim_controls1 = html_tag('table', { :id => @id, :class => classes, :style => styles }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; if title?; 
      ; _slim_controls2 << ("<caption class=\"title\">".freeze); _slim_controls2 << ((captioned_title).to_s); 
      ; _slim_controls2 << ("</caption>".freeze); end; unless (attr :rowcount).zero?; 
      ; _slim_controls2 << ("<colgroup>".freeze); 
      ; if option? 'autowidth'; 
      ; @columns.each do; 
      ; _slim_controls2 << ("<col>".freeze); 
      ; end; else; 
      ; @columns.each do |col|; 
      ; _slim_controls2 << ("<col style=\"width:".freeze); _slim_controls2 << ((col.attr :colpcwidth).to_s); _slim_controls2 << ("%\">".freeze); 
      ; end; end; _slim_controls2 << ("</colgroup>".freeze); [:head, :foot, :body].select {|tblsec| !@rows[tblsec].empty? }.each do |tblsec|; 
      ; 
      ; _slim_controls2 << ("<t".freeze); _slim_controls2 << ((tblsec).to_s); _slim_controls2 << (">".freeze); 
      ; @rows[tblsec].each do |row|; 
      ; _slim_controls2 << ("<tr>".freeze); 
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
      :style=>((@document.attr? :cellbgcolor) ? %(background-color:#{@document.attr :cellbgcolor};) : nil)) do; _slim_controls4 = ''; 
      ; if tblsec == :head; 
      ; _slim_controls4 << ((cell_content).to_s); 
      ; else; 
      ; case cell.style; 
      ; when :asciidoc; 
      ; _slim_controls4 << ("<div>".freeze); _slim_controls4 << ((cell_content).to_s); 
      ; _slim_controls4 << ("</div>".freeze); when :literal; 
      ; _slim_controls4 << ("<div class=\"literal\"><pre>".freeze); _slim_controls4 << ((cell_content).to_s); 
      ; _slim_controls4 << ("</pre></div>".freeze); when :header; 
      ; cell_content.each do |text|; 
      ; _slim_controls4 << ("<p class=\"tableblock header\">".freeze); _slim_controls4 << ((text).to_s); 
      ; _slim_controls4 << ("</p>".freeze); end; else; 
      ; cell_content.each do |text|; 
      ; _slim_controls4 << ("<p class=\"tableblock\">".freeze); _slim_controls4 << ((text).to_s); 
      ; _slim_controls4 << ("</p>".freeze); end; end; end; _slim_controls4; end; _slim_controls2 << ((_slim_controls3).to_s); end; _slim_controls2 << ("</tr>".freeze); end; end; end; _slim_controls2; end; _buf << ((_slim_controls1).to_s); _buf
    end
  end

  def convert_outline(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; unless sections.empty?; 
      ; toclevels ||= (document.attr 'toclevels', DEFAULT_TOCLEVELS).to_i; 
      ; slevel = section_level sections.first; 
      ; _buf << ("<ol class=\"sectlevel".freeze); _buf << ((slevel).to_s); _buf << ("\">".freeze); 
      ; sections.each do |sec|; 
      ; _buf << ("<li><a href=\"#".freeze); 
      ; _buf << ((sec.id).to_s); _buf << ("\">".freeze); _buf << ((section_title sec).to_s); 
      ; _buf << ("</a>".freeze); if (sec.level < toclevels) && (child_toc = converter.convert sec, 'outline'); 
      ; _buf << ((child_toc).to_s); 
      ; end; _buf << ("</li>".freeze); end; _buf << ("</ol>".freeze); end; _buf
    end
  end

  def convert_inline_button(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _slim_controls1 = html_tag('b', { :class => ['button'] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; _slim_controls2 << ((@text).to_s); 
      ; _slim_controls2; end; _buf << ((_slim_controls1).to_s); _buf
    end
  end

  def convert_document(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; slides_content = self.content; 
      ; content_for :slides do; 
      ; unless noheader; 
      ; unless (header_docinfo = docinfo :header, '-revealjs.html').empty?; 
      ; _buf << ((header_docinfo).to_s); 
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
      ; _buf << ("<section".freeze); _temple_html_attributeremover1 = ''; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "title"; _temple_html_attributemerger1[1] = ''; _slim_codeattributes1 = role; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributemerger1[1] << ((_slim_codeattributes1).to_s); end; _temple_html_attributemerger1[1]; _temple_html_attributeremover1 << ((_temple_html_attributemerger1.reject(&:empty?).join(" ")).to_s); _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _buf << (" data-state=\"title\"".freeze); _slim_codeattributes2 = (attr 'title-slide-transition'); if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" data-transition".freeze); else; _buf << (" data-transition=\"".freeze); _buf << ((_slim_codeattributes2).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes3 = (attr 'title-slide-transition-speed'); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" data-transition-speed".freeze); else; _buf << (" data-transition-speed=\"".freeze); _buf << ((_slim_codeattributes3).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes4 = (attr 'title-slide-background'); if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" data-background".freeze); else; _buf << (" data-background=\"".freeze); _buf << ((_slim_codeattributes4).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes5 = (attr 'title-slide-background-size'); if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" data-background-size".freeze); else; _buf << (" data-background-size=\"".freeze); _buf << ((_slim_codeattributes5).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes6 = bg_image; if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" data-background-image".freeze); else; _buf << (" data-background-image=\"".freeze); _buf << ((_slim_codeattributes6).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes7 = bg_video; if _slim_codeattributes7; if _slim_codeattributes7 == true; _buf << (" data-background-video".freeze); else; _buf << (" data-background-video=\"".freeze); _buf << ((_slim_codeattributes7).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes8 = (attr 'title-slide-background-video-loop'); if _slim_codeattributes8; if _slim_codeattributes8 == true; _buf << (" data-background-video-loop".freeze); else; _buf << (" data-background-video-loop=\"".freeze); _buf << ((_slim_codeattributes8).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes9 = (attr 'title-slide-background-video-muted'); if _slim_codeattributes9; if _slim_codeattributes9 == true; _buf << (" data-background-video-muted".freeze); else; _buf << (" data-background-video-muted=\"".freeze); _buf << ((_slim_codeattributes9).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes10 = (attr 'title-slide-background-opacity'); if _slim_codeattributes10; if _slim_codeattributes10 == true; _buf << (" data-background-opacity".freeze); else; _buf << (" data-background-opacity=\"".freeze); _buf << ((_slim_codeattributes10).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes11 = (attr 'title-slide-background-iframe'); if _slim_codeattributes11; if _slim_codeattributes11 == true; _buf << (" data-background-iframe".freeze); else; _buf << (" data-background-iframe=\"".freeze); _buf << ((_slim_codeattributes11).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes12 = (attr 'title-slide-background-color'); if _slim_codeattributes12; if _slim_codeattributes12 == true; _buf << (" data-background-color".freeze); else; _buf << (" data-background-color=\"".freeze); _buf << ((_slim_codeattributes12).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes13 = (attr 'title-slide-background-repeat'); if _slim_codeattributes13; if _slim_codeattributes13 == true; _buf << (" data-background-repeat".freeze); else; _buf << (" data-background-repeat=\"".freeze); _buf << ((_slim_codeattributes13).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes14 = (attr 'title-slide-background-position'); if _slim_codeattributes14; if _slim_codeattributes14 == true; _buf << (" data-background-position".freeze); else; _buf << (" data-background-position=\"".freeze); _buf << ((_slim_codeattributes14).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes15 = (attr 'title-slide-background-transition'); if _slim_codeattributes15; if _slim_codeattributes15 == true; _buf << (" data-background-transition".freeze); else; _buf << (" data-background-transition=\"".freeze); _buf << ((_slim_codeattributes15).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; if (_title_obj = doctitle partition: true, use_fallback: true).subtitle?; 
      ; _buf << ("<h1>".freeze); _buf << ((slice_text _title_obj.title, (_slice = header.option? :slice)).to_s); 
      ; _buf << ("</h1><h2>".freeze); _buf << ((slice_text _title_obj.subtitle, _slice).to_s); 
      ; _buf << ("</h2>".freeze); else; 
      ; _buf << ("<h1>".freeze); _buf << ((@header.title).to_s); 
      ; _buf << ("</h1>".freeze); end; preamble = @document.find_by context: :preamble; 
      ; unless preamble.nil? or preamble.length == 0; 
      ; _buf << ("<div class=\"preamble\">".freeze); _buf << ((preamble.pop.content).to_s); 
      ; _buf << ("</div>".freeze); end; _buf << ((generate_authors(@document)).to_s); 
      ; _buf << ("</section>".freeze); 
      ; end; end; _buf << ((slides_content).to_s); 
      ; unless (footer_docinfo = docinfo :footer, '-revealjs.html').empty?; 
      ; _buf << ((footer_docinfo).to_s); 
      ; 
      ; end; end; _buf << ("<!DOCTYPE html><html".freeze); 
      ; _slim_codeattributes16 = (attr :lang, 'en' unless attr? :nolang); if _slim_codeattributes16; if _slim_codeattributes16 == true; _buf << (" lang".freeze); else; _buf << (" lang=\"".freeze); _buf << ((_slim_codeattributes16).to_s); _buf << ("\"".freeze); end; end; _buf << ("><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, minimal-ui\"><title>".freeze); 
      ; 
      ; 
      ; 
      ; 
      ; _buf << (((doctitle sanitize: true, use_fallback: true)).to_s); 
      ; 
      ; _buf << ("</title>".freeze); if RUBY_ENGINE == 'opal' && JAVASCRIPT_PLATFORM == 'node'; 
      ; revealjsdir = (attr :revealjsdir, 'node_modules/reveal.js'); 
      ; else; 
      ; revealjsdir = (attr :revealjsdir, 'reveal.js'); 
      ; end; unless (asset_uri_scheme = (attr 'asset-uri-scheme', 'https')).empty?; 
      ; asset_uri_scheme = %(#{asset_uri_scheme}:); 
      ; end; cdn_base = %(#{asset_uri_scheme}//cdnjs.cloudflare.com/ajax/libs); 
      ; [:description, :keywords, :author, :copyright].each do |key|; 
      ; if attr? key; 
      ; _buf << ("<meta".freeze); _slim_codeattributes17 = key; if _slim_codeattributes17; if _slim_codeattributes17 == true; _buf << (" name".freeze); else; _buf << (" name=\"".freeze); _buf << ((_slim_codeattributes17).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes18 = (attr key); if _slim_codeattributes18; if _slim_codeattributes18 == true; _buf << (" content".freeze); else; _buf << (" content=\"".freeze); _buf << ((_slim_codeattributes18).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; end; end; if attr? 'favicon'; 
      ; if (icon_href = attr 'favicon').empty?; 
      ; icon_href = 'favicon.ico'; 
      ; icon_type = 'image/x-icon'; 
      ; elsif (icon_ext = File.extname icon_href); 
      ; icon_type = icon_ext == '.ico' ? 'image/x-icon' : %(image/#{icon_ext.slice 1, icon_ext.length}); 
      ; else; 
      ; icon_type = 'image/x-icon'; 
      ; end; _buf << ("<link rel=\"icon\" type=\"".freeze); _buf << ((icon_type).to_s); _buf << ("\" href=\"".freeze); _buf << ((icon_href).to_s); _buf << ("\">".freeze); 
      ; end; linkcss = (attr? 'linkcss'); 
      ; _buf << ("<link rel=\"stylesheet\" href=\"".freeze); _buf << ((revealjsdir).to_s); _buf << ("/dist/reset.css\"><link rel=\"stylesheet\" href=\"".freeze); 
      ; _buf << ((revealjsdir).to_s); _buf << ("/dist/reveal.css\"><link rel=\"stylesheet\"".freeze); 
      ; 
      ; 
      ; _slim_codeattributes19 = (attr :revealjs_customtheme, %(#{revealjsdir}/dist/theme/#{attr 'revealjs_theme', 'black'}.css)); if _slim_codeattributes19; if _slim_codeattributes19 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes19).to_s); _buf << ("\"".freeze); end; end; _buf << (" id=\"theme\"><!--This CSS is generated by the Asciidoctor reveal.js converter to further integrate AsciiDoc's existing semantic with reveal.js--><style type=\"text/css\">.reveal div.right {\n  float: right\n}\n\n/* source blocks */\n.reveal .listingblock.stretch > .content {\n  height: 100%\n}\n\n.reveal .listingblock.stretch > .content > pre {\n  height: 100%\n}\n\n.reveal .listingblock.stretch > .content > pre > code {\n  height: 100%;\n  max-height: 100%\n}\n\n/* auto-animate feature */\n/* hide the scrollbar when auto-animating source blocks */\n.reveal pre[data-auto-animate-target] {\n  overflow: hidden;\n}\n\n.reveal pre[data-auto-animate-target] code {\n  overflow: hidden;\n}\n\n/* add a min width to avoid horizontal shift on line numbers */\ncode.hljs .hljs-ln-line.hljs-ln-n {\n  min-width: 1.25em;\n}\n\n/* tables */\ntable {\n  border-collapse: collapse;\n  border-spacing: 0\n}\n\ntable {\n  margin-bottom: 1.25em;\n  border: solid 1px #dedede\n}\n\ntable thead tr th, table thead tr td, table tfoot tr th, table tfoot tr td {\n  padding: .5em .625em .625em;\n  font-size: inherit;\n  text-align: left\n}\n\ntable tr th, table tr td {\n  padding: .5625em .625em;\n  font-size: inherit\n}\n\ntable thead tr th, table tfoot tr th, table tbody tr td, table tr td, table tfoot tr td {\n  display: table-cell;\n  line-height: 1.6\n}\n\ntd.tableblock > .content {\n  margin-bottom: 1.25em\n}\n\ntd.tableblock > .content > :last-child {\n  margin-bottom: -1.25em\n}\n\ntable.tableblock, th.tableblock, td.tableblock {\n  border: 0 solid #dedede\n}\n\ntable.grid-all > thead > tr > .tableblock, table.grid-all > tbody > tr > .tableblock {\n  border-width: 0 1px 1px 0\n}\n\ntable.grid-all > tfoot > tr > .tableblock {\n  border-width: 1px 1px 0 0\n}\n\ntable.grid-cols > * > tr > .tableblock {\n  border-width: 0 1px 0 0\n}\n\ntable.grid-rows > thead > tr > .tableblock, table.grid-rows > tbody > tr > .tableblock {\n  border-width: 0 0 1px\n}\n\ntable.grid-rows > tfoot > tr > .tableblock {\n  border-width: 1px 0 0\n}\n\ntable.grid-all > * > tr > .tableblock:last-child, table.grid-cols > * > tr > .tableblock:last-child {\n  border-right-width: 0\n}\n\ntable.grid-all > tbody > tr:last-child > .tableblock, table.grid-all > thead:last-child > tr > .tableblock, table.grid-rows > tbody > tr:last-child > .tableblock, table.grid-rows > thead:last-child > tr > .tableblock {\n  border-bottom-width: 0\n}\n\ntable.frame-all {\n  border-width: 1px\n}\n\ntable.frame-sides {\n  border-width: 0 1px\n}\n\ntable.frame-topbot, table.frame-ends {\n  border-width: 1px 0\n}\n\n.reveal table th.halign-left, .reveal table td.halign-left {\n  text-align: left\n}\n\n.reveal table th.halign-right, .reveal table td.halign-right {\n  text-align: right\n}\n\n.reveal table th.halign-center, .reveal table td.halign-center {\n  text-align: center\n}\n\n.reveal table th.valign-top, .reveal table td.valign-top {\n  vertical-align: top\n}\n\n.reveal table th.valign-bottom, .reveal table td.valign-bottom {\n  vertical-align: bottom\n}\n\n.reveal table th.valign-middle, .reveal table td.valign-middle {\n  vertical-align: middle\n}\n\ntable thead th, table tfoot th {\n  font-weight: bold\n}\n\ntbody tr th {\n  display: table-cell;\n  line-height: 1.6\n}\n\ntbody tr th, tbody tr th p, tfoot tr th, tfoot tr th p {\n  font-weight: bold\n}\n\nthead {\n  display: table-header-group\n}\n\n.reveal table.grid-none th, .reveal table.grid-none td {\n  border-bottom: 0 !important\n}\n\n/* kbd macro */\nkbd {\n  font-family: \"Droid Sans Mono\", \"DejaVu Sans Mono\", monospace;\n  display: inline-block;\n  color: rgba(0, 0, 0, .8);\n  font-size: .65em;\n  line-height: 1.45;\n  background: #f7f7f7;\n  border: 1px solid #ccc;\n  -webkit-border-radius: 3px;\n  border-radius: 3px;\n  -webkit-box-shadow: 0 1px 0 rgba(0, 0, 0, .2), 0 0 0 .1em white inset;\n  box-shadow: 0 1px 0 rgba(0, 0, 0, .2), 0 0 0 .1em #fff inset;\n  margin: 0 .15em;\n  padding: .2em .5em;\n  vertical-align: middle;\n  position: relative;\n  top: -.1em;\n  white-space: nowrap\n}\n\n.keyseq kbd:first-child {\n  margin-left: 0\n}\n\n.keyseq kbd:last-child {\n  margin-right: 0\n}\n\n/* callouts */\n.conum[data-value] {\n  display: inline-block;\n  color: #fff !important;\n  background: rgba(0, 0, 0, .8);\n  -webkit-border-radius: 50%;\n  border-radius: 50%;\n  text-align: center;\n  font-size: .75em;\n  width: 1.67em;\n  height: 1.67em;\n  line-height: 1.67em;\n  font-family: \"Open Sans\", \"DejaVu Sans\", sans-serif;\n  font-style: normal;\n  font-weight: bold\n}\n\n.conum[data-value] * {\n  color: #fff !important\n}\n\n.conum[data-value] + b {\n  display: none\n}\n\n.conum[data-value]:after {\n  content: attr(data-value)\n}\n\npre .conum[data-value] {\n  position: relative;\n  top: -.125em\n}\n\nb.conum * {\n  color: inherit !important\n}\n\n.conum:not([data-value]):empty {\n  display: none\n}\n\n/* Callout list */\n.hdlist > table, .colist > table {\n  border: 0;\n  background: none\n}\n\n.hdlist > table > tbody > tr, .colist > table > tbody > tr {\n  background: none\n}\n\ntd.hdlist1, td.hdlist2 {\n  vertical-align: top;\n  padding: 0 .625em\n}\n\ntd.hdlist1 {\n  font-weight: bold;\n  padding-bottom: 1.25em\n}\n\n/* Disabled from Asciidoctor CSS because it caused callout list to go under the\n * source listing when .stretch is applied (see #335)\n * .literalblock+.colist,.listingblock+.colist{margin-top:-.5em} */\n.colist td:not([class]):first-child {\n  padding: .4em .75em 0;\n  line-height: 1;\n  vertical-align: top\n}\n\n.colist td:not([class]):first-child img {\n  max-width: none\n}\n\n.colist td:not([class]):last-child {\n  padding: .25em 0\n}\n\n/* Override Asciidoctor CSS that causes issues with reveal.js features */\n.reveal .hljs table {\n  border: 0\n}\n\n/* Callout list rows would have a bottom border with some reveal.js themes (see #335) */\n.reveal .colist > table th, .reveal .colist > table td {\n  border-bottom: 0\n}\n\n/* Fixes line height with Highlight.js source listing when linenums enabled (see #331) */\n.reveal .hljs table thead tr th, .reveal .hljs table tfoot tr th, .reveal .hljs table tbody tr td, .reveal .hljs table tr td, .reveal .hljs table tfoot tr td {\n  line-height: inherit\n}\n\n/* Columns layout */\n.columns .slide-content {\n  display: flex;\n}\n\n.columns.wrap .slide-content {\n  flex-wrap: wrap;\n}\n\n.columns.is-vcentered .slide-content {\n  align-items: center;\n}\n\n.columns .slide-content > .column {\n  display: block;\n  flex-basis: 0;\n  flex-grow: 1;\n  flex-shrink: 1;\n}\n\n.columns .slide-content > .column > * {\n  padding: .75rem;\n}\n\n/* See #353 */\n.columns.wrap .slide-content > .column {\n  flex-basis: auto;\n}\n\n.columns .slide-content > .column.is-full {\n  flex: none;\n  width: 100%;\n}\n\n.columns .slide-content > .column.is-four-fifths {\n  flex: none;\n  width: 80%;\n}\n\n.columns .slide-content > .column.is-three-quarters {\n  flex: none;\n  width: 75%;\n}\n\n.columns .slide-content > .column.is-two-thirds {\n  flex: none;\n  width: 66.6666%;\n}\n\n.columns .slide-content > .column.is-three-fifths {\n  flex: none;\n  width: 60%;\n}\n\n.columns .slide-content > .column.is-half {\n  flex: none;\n  width: 50%;\n}\n\n.columns .slide-content > .column.is-two-fifths {\n  flex: none;\n  width: 40%;\n}\n\n.columns .slide-content > .column.is-one-third {\n  flex: none;\n  width: 33.3333%;\n}\n\n.columns .slide-content > .column.is-one-quarter {\n  flex: none;\n  width: 25%;\n}\n\n.columns .slide-content > .column.is-one-fifth {\n  flex: none;\n  width: 20%;\n}\n\n.columns .slide-content > .column.has-text-left {\n  text-align: left;\n}\n\n.columns .slide-content > .column.has-text-justified {\n  text-align: justify;\n}\n\n.columns .slide-content > .column.has-text-right {\n  text-align: right;\n}\n\n.columns .slide-content > .column.has-text-left {\n  text-align: left;\n}\n\n.columns .slide-content > .column.has-text-justified {\n  text-align: justify;\n}\n\n.columns .slide-content > .column.has-text-right {\n  text-align: right;\n}\n\n.text-left {\n  text-align: left !important\n}\n\n.text-right {\n  text-align: right !important\n}\n\n.text-center {\n  text-align: center !important\n}\n\n.text-justify {\n  text-align: justify !important\n}\n\n.footnotes {\n  border-top: 1px solid rgba(0, 0, 0, 0.2);\n  padding: 0.5em 0 0 0;\n  font-size: 0.65em;\n  margin-top: 4em;\n}\n\n.byline {\n  font-size:.8em\n}\nul.byline {\n  list-style-type: none;\n}\nul.byline li + li {\n  margin-top: 0.25em;\n}\n</style>".freeze); 
      ; 
      ; 
      ; 
      ; if attr? :icons, 'font'; 
      ; 
      ; if attr? 'iconfont-remote'; 
      ; if (iconfont_cdn = (attr 'iconfont-cdn')); 
      ; _buf << ("<link rel=\"stylesheet\"".freeze); _slim_codeattributes20 = iconfont_cdn; if _slim_codeattributes20; if _slim_codeattributes20 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes20).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; else; 
      ; 
      ; font_awesome_version = (attr 'font-awesome-version', '5.15.1'); 
      ; _buf << ("<link rel=\"stylesheet\"".freeze); _slim_codeattributes21 = %(#{cdn_base}/font-awesome/#{font_awesome_version}/css/all.min.css); if _slim_codeattributes21; if _slim_codeattributes21 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes21).to_s); _buf << ("\"".freeze); end; end; _buf << ("><link rel=\"stylesheet\"".freeze); 
      ; _slim_codeattributes22 = %(#{cdn_base}/font-awesome/#{font_awesome_version}/css/v4-shims.min.css); if _slim_codeattributes22; if _slim_codeattributes22 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes22).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; end; else; 
      ; _buf << ("<link rel=\"stylesheet\"".freeze); _slim_codeattributes23 = (normalize_web_path %(#{attr 'iconfont-name', 'font-awesome'}.css), (attr 'stylesdir', ''), false); if _slim_codeattributes23; if _slim_codeattributes23 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes23).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; end; end; _buf << ((generate_stem(cdn_base)).to_s); 
      ; syntax_hl = self.syntax_highlighter; 
      ; if syntax_hl && (syntax_hl.docinfo? :head); 
      ; _buf << ((syntax_hl.docinfo :head, self, cdn_base_url: cdn_base, linkcss: linkcss, self_closing_tag_slash: '/').to_s); 
      ; end; if attr? :customcss; 
      ; _buf << ("<link rel=\"stylesheet\"".freeze); _slim_codeattributes24 = ((customcss = attr :customcss).empty? ? 'asciidoctor-revealjs.css' : customcss); if _slim_codeattributes24; if _slim_codeattributes24 == true; _buf << (" href".freeze); else; _buf << (" href=\"".freeze); _buf << ((_slim_codeattributes24).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; end; unless (_docinfo = docinfo :head, '-revealjs.html').empty?; 
      ; _buf << ((_docinfo).to_s); 
      ; end; _buf << ("</head><body><div class=\"reveal\"><div class=\"slides\">".freeze); 
      ; 
      ; 
      ; 
      ; yield_content :slides; 
      ; _buf << ("</div></div><script src=\"".freeze); _buf << ((revealjsdir).to_s); _buf << ("/dist/reveal.js\"></script><script>Array.prototype.slice.call(document.querySelectorAll('.slides section')).forEach(function(slide) {\n  if (slide.getAttribute('data-background-color')) return;\n  // user needs to explicitly say he wants CSS color to override otherwise we might break custom css or theme (#226)\n  if (!(slide.classList.contains('canvas') || slide.classList.contains('background'))) return;\n  var bgColor = getComputedStyle(slide).backgroundColor;\n  if (bgColor !== 'rgba(0, 0, 0, 0)' && bgColor !== 'transparent') {\n    slide.setAttribute('data-background-color', bgColor);\n    slide.style.backgroundColor = 'transparent';\n  }\n});\n\n// More info about config & dependencies:\n// - https://github.com/hakimel/reveal.js#configuration\n// - https://github.com/hakimel/reveal.js#dependencies\nReveal.initialize({\n  // Display presentation control arrows\n  controls: ".freeze); 
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
      ; _buf << ((to_boolean(attr 'revealjs_controls', true)).to_s); _buf << (",\n  // Help the user learn the controls by providing hints, for example by\n  // bouncing the down arrow when they first encounter a vertical slide\n  controlsTutorial: ".freeze); 
      ; 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_controlstutorial', true)).to_s); _buf << (",\n  // Determines where controls appear, \"edges\" or \"bottom-right\"\n  controlsLayout: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_controlslayout', 'bottom-right').to_s); _buf << ("',\n  // Visibility rule for backwards navigation arrows; \"faded\", \"hidden\"\n  // or \"visible\"\n  controlsBackArrows: '".freeze); 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_controlsbackarrows', 'faded').to_s); _buf << ("',\n  // Display a presentation progress bar\n  progress: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_progress', true)).to_s); _buf << (",\n  // Display the page number of the current slide\n  slideNumber: ".freeze); 
      ; 
      ; _buf << ((to_valid_slidenumber(attr 'revealjs_slidenumber', false)).to_s); _buf << (",\n  // Control which views the slide number displays on\n  showSlideNumber: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_showslidenumber', 'all').to_s); _buf << ("',\n  // Add the current slide number to the URL hash so that reloading the\n  // page/copying the URL will return you to the same slide\n  hash: ".freeze); 
      ; 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_hash', false)).to_s); _buf << (",\n  // Push each slide change to the browser history. Implies `hash: true`\n  history: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_history', false)).to_s); _buf << (",\n  // Enable keyboard shortcuts for navigation\n  keyboard: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_keyboard', true)).to_s); _buf << (",\n  // Enable the slide overview mode\n  overview: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_overview', true)).to_s); _buf << (",\n  // Disables the default reveal.js slide layout so that you can use custom CSS layout\n  disableLayout: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_disablelayout', false)).to_s); _buf << (",\n  // Vertical centering of slides\n  center: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_center', true)).to_s); _buf << (",\n  // Enables touch navigation on devices with touch input\n  touch: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_touch', true)).to_s); _buf << (",\n  // Loop the presentation\n  loop: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_loop', false)).to_s); _buf << (",\n  // Change the presentation direction to be RTL\n  rtl: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_rtl', false)).to_s); _buf << (",\n  // See https://github.com/hakimel/reveal.js/#navigation-mode\n  navigationMode: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_navigationmode', 'default').to_s); _buf << ("',\n  // Randomizes the order of slides each time the presentation loads\n  shuffle: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_shuffle', false)).to_s); _buf << (",\n  // Turns fragments on and off globally\n  fragments: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_fragments', true)).to_s); _buf << (",\n  // Flags whether to include the current fragment in the URL,\n  // so that reloading brings you to the same fragment position\n  fragmentInURL: ".freeze); 
      ; 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_fragmentinurl', false)).to_s); _buf << (",\n  // Flags if the presentation is running in an embedded mode,\n  // i.e. contained within a limited portion of the screen\n  embedded: ".freeze); 
      ; 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_embedded', false)).to_s); _buf << (",\n  // Flags if we should show a help overlay when the questionmark\n  // key is pressed\n  help: ".freeze); 
      ; 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_help', true)).to_s); _buf << (",\n  // Flags if speaker notes should be visible to all viewers\n  showNotes: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_shownotes', false)).to_s); _buf << (",\n  // Global override for autolaying embedded media (video/audio/iframe)\n  // - null: Media will only autoplay if data-autoplay is present\n  // - true: All media will autoplay, regardless of individual setting\n  // - false: No media will autoplay, regardless of individual setting\n  autoPlayMedia: ".freeze); 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_autoplaymedia', 'null').to_s); _buf << (",\n  // Global override for preloading lazy-loaded iframes\n  // - null: Iframes with data-src AND data-preload will be loaded when within\n  //   the viewDistance, iframes with only data-src will be loaded when visible\n  // - true: All iframes with data-src will be loaded when within the viewDistance\n  // - false: All iframes with data-src will be loaded only when visible\n  preloadIframes: ".freeze); 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_preloadiframes', 'null').to_s); _buf << (",\n  // Number of milliseconds between automatically proceeding to the\n  // next slide, disabled when set to 0, this value can be overwritten\n  // by using a data-autoslide attribute on your slides\n  autoSlide: ".freeze); 
      ; 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_autoslide', 0).to_s); _buf << (",\n  // Stop auto-sliding after user input\n  autoSlideStoppable: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_autoslidestoppable', true)).to_s); _buf << (",\n  // Use this method for navigation when auto-sliding\n  autoSlideMethod: ".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_autoslidemethod', 'Reveal.navigateNext').to_s); _buf << (",\n  // Specify the average time in seconds that you think you will spend\n  // presenting each slide. This is used to show a pacing timer in the\n  // speaker view\n  defaultTiming: ".freeze); 
      ; 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_defaulttiming', 120).to_s); _buf << (",\n  // Specify the total time in seconds that is available to\n  // present.  If this is set to a nonzero value, the pacing\n  // timer will work out the time available for each slide,\n  // instead of using the defaultTiming value\n  totalTime: ".freeze); 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_totaltime', 0).to_s); _buf << (",\n  // Specify the minimum amount of time you want to allot to\n  // each slide, if using the totalTime calculation method.  If\n  // the automated time allocation causes slide pacing to fall\n  // below this threshold, then you will see an alert in the\n  // speaker notes window\n  minimumTimePerSlide: ".freeze); 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_minimumtimeperslide', 0).to_s); _buf << (",\n  // Enable slide navigation via mouse wheel\n  mouseWheel: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_mousewheel', false)).to_s); _buf << (",\n  // Hide cursor if inactive\n  hideInactiveCursor: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_hideinactivecursor', true)).to_s); _buf << (",\n  // Time before the cursor is hidden (in ms)\n  hideCursorTime: ".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_hidecursortime', 5000).to_s); _buf << (",\n  // Hides the address bar on mobile devices\n  hideAddressBar: ".freeze); 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_hideaddressbar', true)).to_s); _buf << (",\n  // Opens links in an iframe preview overlay\n  // Add `data-preview-link` and `data-preview-link=\"false\"` to customise each link\n  // individually\n  previewLinks: ".freeze); 
      ; 
      ; 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_previewlinks', false)).to_s); _buf << (",\n  // Transition style (e.g., none, fade, slide, convex, concave, zoom)\n  transition: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_transition', 'slide').to_s); _buf << ("',\n  // Transition speed (e.g., default, fast, slow)\n  transitionSpeed: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_transitionspeed', 'default').to_s); _buf << ("',\n  // Transition style for full page slide backgrounds (e.g., none, fade, slide, convex, concave, zoom)\n  backgroundTransition: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_backgroundtransition', 'fade').to_s); _buf << ("',\n  // Number of slides away from the current that are visible\n  viewDistance: ".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_viewdistance', 3).to_s); _buf << (",\n  // Number of slides away from the current that are visible on mobile\n  // devices. It is advisable to set this to a lower number than\n  // viewDistance in order to save resources.\n  mobileViewDistance: ".freeze); 
      ; 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_mobileviewdistance', 3).to_s); _buf << (",\n  // Parallax background image (e.g., \"'https://s3.amazonaws.com/hakim-static/reveal-js/reveal-parallax-1.jpg'\")\n  parallaxBackgroundImage: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_parallaxbackgroundimage', '').to_s); _buf << ("',\n  // Parallax background size in CSS syntax (e.g., \"2100px 900px\")\n  parallaxBackgroundSize: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_parallaxbackgroundsize', '').to_s); _buf << ("',\n  // Number of pixels to move the parallax background per slide\n  // - Calculated automatically unless specified\n  // - Set to 0 to disable movement along an axis\n  parallaxBackgroundHorizontal: ".freeze); 
      ; 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_parallaxbackgroundhorizontal', 'null').to_s); _buf << (",\n  parallaxBackgroundVertical: ".freeze); 
      ; _buf << ((attr 'revealjs_parallaxbackgroundvertical', 'null').to_s); _buf << (",\n  // The display mode that will be used to show slides\n  display: '".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_display', 'block').to_s); _buf << ("',\n\n  // The \"normal\" size of the presentation, aspect ratio will be preserved\n  // when the presentation is scaled to fit different resolutions. Can be\n  // specified using percentage units.\n  width: ".freeze); 
      ; 
      ; 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_width', 960).to_s); _buf << (",\n  height: ".freeze); 
      ; _buf << ((attr 'revealjs_height', 700).to_s); _buf << (",\n\n  // Factor of the display size that should remain empty around the content\n  margin: ".freeze); 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_margin', 0.1).to_s); _buf << (",\n\n  // Bounds for smallest/largest possible scale to apply to content\n  minScale: ".freeze); 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_minscale', 0.2).to_s); _buf << (",\n  maxScale: ".freeze); 
      ; _buf << ((attr 'revealjs_maxscale', 1.5).to_s); _buf << (",\n\n  // PDF Export Options\n  // Put each fragment on a separate page\n  pdfSeparateFragments: ".freeze); 
      ; 
      ; 
      ; 
      ; _buf << ((to_boolean(attr 'revealjs_pdfseparatefragments', true)).to_s); _buf << (",\n  // For slides that do not fit on a page, max number of pages\n  pdfMaxPagesPerSlide: ".freeze); 
      ; 
      ; _buf << ((attr 'revealjs_pdfmaxpagesperslide', 1).to_s); _buf << (",\n\n  // Optional libraries used to extend on reveal.js\n  dependencies: [\n      ".freeze); 
      ; 
      ; 
      ; 
      ; _buf << ((revealjs_dependencies(document, self, revealjsdir)).to_s); 
      ; _buf << ("\n  ],\n});</script><script>var dom = {};\ndom.slides = document.querySelector('.reveal .slides');\n\nfunction getRemainingHeight(element, slideElement, height) {\n  height = height || 0;\n  if (element) {\n    var newHeight, oldHeight = element.style.height;\n    // Change the .stretch element height to 0 in order find the height of all\n    // the other elements\n    element.style.height = '0px';\n    // In Overview mode, the parent (.slide) height is set of 700px.\n    // Restore it temporarily to its natural height.\n    slideElement.style.height = 'auto';\n    newHeight = height - slideElement.offsetHeight;\n    // Restore the old height, just in case\n    element.style.height = oldHeight + 'px';\n    // Clear the parent (.slide) height. .removeProperty works in IE9+\n    slideElement.style.removeProperty('height');\n    return newHeight;\n  }\n  return height;\n}\n\nfunction layoutSlideContents(width, height) {\n  // Handle sizing of elements with the 'stretch' class\n  toArray(dom.slides.querySelectorAll('section .stretch')).forEach(function (element) {\n    // Determine how much vertical space we can use\n    var limit = 5; // hard limit\n    var parent = element.parentNode;\n    while (parent.nodeName !== 'SECTION' && limit > 0) {\n      parent = parent.parentNode;\n      limit--;\n    }\n    if (limit === 0) {\n      // unable to find parent, aborting!\n      return;\n    }\n    var remainingHeight = getRemainingHeight(element, parent, height);\n    // Consider the aspect ratio of media elements\n    if (/(img|video)/gi.test(element.nodeName)) {\n      var nw = element.naturalWidth || element.videoWidth, nh = element.naturalHeight || element.videoHeight;\n      var es = Math.min(width / nw, remainingHeight / nh);\n      element.style.width = (nw * es) + 'px';\n      element.style.height = (nh * es) + 'px';\n    } else {\n      element.style.width = width + 'px';\n      element.style.height = remainingHeight + 'px';\n    }\n  });\n}\n\nfunction toArray(o) {\n  return Array.prototype.slice.call(o);\n}\n\nReveal.addEventListener('slidechanged', function () {\n  layoutSlideContents(".freeze); 
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
      ; _buf << ((attr 'revealjs_width', 960).to_s); _buf << (", ".freeze); _buf << ((attr 'revealjs_height', 700).to_s); _buf << (")\n});\nReveal.addEventListener('ready', function () {\n  layoutSlideContents(".freeze); 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_width', 960).to_s); _buf << (", ".freeze); _buf << ((attr 'revealjs_height', 700).to_s); _buf << (")\n});\nReveal.addEventListener('resize', function () {\n  layoutSlideContents(".freeze); 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_width', 960).to_s); _buf << (", ".freeze); _buf << ((attr 'revealjs_height', 700).to_s); _buf << (")\n});</script>".freeze); 
      ; 
      ; 
      ; if syntax_hl && (syntax_hl.docinfo? :footer); 
      ; _buf << ((syntax_hl.docinfo :footer, self, cdn_base_url: cdn_base, linkcss: linkcss, self_closing_tag_slash: '/').to_s); 
      ; 
      ; end; unless (docinfo_content = (docinfo :footer, '.html')).empty?; 
      ; _buf << ((docinfo_content).to_s); 
      ; end; _buf << ("</body></html>".freeze); _buf
    end
  end

  def convert_inline_menu(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; menu = attr 'menu'; 
      ; menuitem = attr 'menuitem'; 
      ; if !(submenus = attr 'submenus').empty?; 
      ; _slim_controls1 = html_tag('span', { :class => ['menuseq'] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; _slim_controls2 << ("<span class=\"menu\">".freeze); _slim_controls2 << ((menu).to_s); 
      ; _slim_controls2 << ("</span>&#160;&#9656;&#32;".freeze); 
      ; _slim_controls2 << ((submenus.map {|submenu| %(<span class="submenu">#{submenu}</span>&#160;&#9656;&#32;) }.join).to_s); 
      ; _slim_controls2 << ("<span class=\"menuitem\">".freeze); _slim_controls2 << ((menuitem).to_s); 
      ; _slim_controls2 << ("</span>".freeze); _slim_controls2; end; _buf << ((_slim_controls1).to_s); elsif !menuitem.nil?; 
      ; _slim_controls3 = html_tag('span', { :class => ['menuseq'] }.merge(data_attrs(@attributes))) do; _slim_controls4 = ''; 
      ; _slim_controls4 << ("<span class=\"menu\">".freeze); _slim_controls4 << ((menu).to_s); 
      ; _slim_controls4 << ("</span>&#160;&#9656;&#32;<span class=\"menuitem\">".freeze); 
      ; _slim_controls4 << ((menuitem).to_s); 
      ; _slim_controls4 << ("</span>".freeze); _slim_controls4; end; _buf << ((_slim_controls3).to_s); else; 
      ; _slim_controls5 = html_tag('span', { :class => ['menu'] }.merge(data_attrs(@attributes))) do; _slim_controls6 = ''; 
      ; _slim_controls6 << ((menu).to_s); 
      ; _slim_controls6; end; _buf << ((_slim_controls5).to_s); end; _buf
    end
  end

  def convert_admonition(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; if (has_role? 'aside') or (has_role? 'speaker') or (has_role? 'notes'); 
      ; _buf << ("<aside class=\"notes\">".freeze); _buf << ((resolve_content).to_s); 
      ; _buf << ("</aside>".freeze); 
      ; else; 
      ; _slim_controls1 = html_tag('div', { :id => @id, :class => ['admonitionblock', (attr :name), role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; _slim_controls2 << ("<table><tr><td class=\"icon\">".freeze); 
      ; 
      ; if @document.attr? :icons, 'font'; 
      ; icon_mapping = Hash['caution', 'fire', 'important', 'exclamation-circle', 'note', 'info-circle', 'tip', 'lightbulb-o', 'warning', 'warning']; 
      ; _slim_controls2 << ("<i".freeze); _temple_html_attributeremover1 = ''; _slim_codeattributes1 = %(fa fa-#{icon_mapping[attr :name]}); if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes1).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\"".freeze); _slim_controls2 << ((_temple_html_attributeremover1).to_s); _slim_controls2 << ("\"".freeze); end; _slim_codeattributes2 = (attr :textlabel || @caption); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls2 << (" title".freeze); else; _slim_controls2 << (" title=\"".freeze); _slim_controls2 << ((_slim_codeattributes2).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_controls2 << ("></i>".freeze); 
      ; elsif @document.attr? :icons; 
      ; _slim_controls2 << ("<img".freeze); _slim_codeattributes3 = icon_uri(attr :name); if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" src".freeze); else; _slim_controls2 << (" src=\"".freeze); _slim_controls2 << ((_slim_codeattributes3).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes4 = @caption; if _slim_codeattributes4; if _slim_codeattributes4 == true; _slim_controls2 << (" alt".freeze); else; _slim_controls2 << (" alt=\"".freeze); _slim_controls2 << ((_slim_codeattributes4).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_controls2 << (">".freeze); 
      ; else; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << (((attr :textlabel) || @caption).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; _slim_controls2 << ("</td><td class=\"content\">".freeze); 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; _slim_controls2 << ((content).to_s); 
      ; _slim_controls2 << ("</td></tr></table>".freeze); _slim_controls2; end; _buf << ((_slim_controls1).to_s); end; _buf
    end
  end

  def convert_open(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; if @style == 'abstract'; 
      ; if @parent == @document && @document.doctype == 'book'; 
      ; puts 'asciidoctor: WARNING: abstract block cannot be used in a document without a title when doctype is book. Excluding block content.'; 
      ; else; 
      ; _slim_controls1 = html_tag('div', { :id => @id, :class => ['quoteblock', 'abstract', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; _slim_controls2 << ("<blockquote>".freeze); _slim_controls2 << ((content).to_s); 
      ; _slim_controls2 << ("</blockquote>".freeze); _slim_controls2; end; _buf << ((_slim_controls1).to_s); end; elsif @style == 'partintro' && (@level != 0 || @parent.context != :section || @document.doctype != 'book'); 
      ; puts 'asciidoctor: ERROR: partintro block can only be used when doctype is book and it\'s a child of a book part. Excluding block content.'; 
      ; else; 
      ; if (has_role? 'aside') or (has_role? 'speaker') or (has_role? 'notes'); 
      ; _buf << ("<aside class=\"notes\">".freeze); _buf << ((resolve_content).to_s); 
      ; _buf << ("</aside>".freeze); 
      ; else; 
      ; _slim_controls3 = html_tag('div', { :id => @id, :class => ['openblock', (@style != 'open' ? @style : nil), role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls4 = ''; 
      ; if title?; 
      ; _slim_controls4 << ("<div class=\"title\">".freeze); _slim_controls4 << ((title).to_s); 
      ; _slim_controls4 << ("</div>".freeze); end; _slim_controls4 << ("<div class=\"content\">".freeze); _slim_controls4 << ((content).to_s); 
      ; _slim_controls4 << ("</div>".freeze); _slim_controls4; end; _buf << ((_slim_controls3).to_s); end; end; _buf
    end
  end

  def convert_inline_footnote(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; footnote = slide_footnote(self); 
      ; index = footnote.attr(:index); 
      ; id = footnote.id; 
      ; if @type == :xref; 
      ; _slim_controls1 = html_tag('sup', { :class => ['footnoteref'] }.merge(data_attrs(footnote.attributes))) do; _slim_controls2 = ''; 
      ; _slim_controls2 << ("[<span class=\"footnote\" title=\"View footnote.\">".freeze); 
      ; _slim_controls2 << ((index).to_s); 
      ; _slim_controls2 << ("</span>]".freeze); 
      ; _slim_controls2; end; _buf << ((_slim_controls1).to_s); else; 
      ; _slim_controls3 = html_tag('sup', { :id => ("_footnote_#{id}" if id), :class => ['footnote'] }.merge(data_attrs(footnote.attributes))) do; _slim_controls4 = ''; 
      ; _slim_controls4 << ("[<span class=\"footnote\" title=\"View footnote.\">".freeze); 
      ; _slim_controls4 << ((index).to_s); 
      ; _slim_controls4 << ("</span>]".freeze); 
      ; _slim_controls4; end; _buf << ((_slim_controls3).to_s); end; _buf
    end
  end

  def convert_verse(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _slim_controls1 = html_tag('div', { :id => @id, :class => ['verseblock', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; _slim_controls2 << ("<pre class=\"content\">".freeze); _slim_controls2 << ((content).to_s); 
      ; _slim_controls2 << ("</pre>".freeze); attribution = (attr? :attribution) ? (attr :attribution) : nil; 
      ; citetitle = (attr? :citetitle) ? (attr :citetitle) : nil; 
      ; if attribution || citetitle; 
      ; _slim_controls2 << ("<div class=\"attribution\">".freeze); 
      ; if citetitle; 
      ; _slim_controls2 << ("<cite>".freeze); _slim_controls2 << ((citetitle).to_s); 
      ; _slim_controls2 << ("</cite>".freeze); end; if attribution; 
      ; if citetitle; 
      ; _slim_controls2 << ("<br>".freeze); 
      ; end; _slim_controls2 << ("&#8212; ".freeze); _slim_controls2 << ((attribution).to_s); 
      ; end; _slim_controls2 << ("</div>".freeze); end; _slim_controls2; end; _buf << ((_slim_controls1).to_s); _buf
    end
  end

  def convert_quote(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _slim_controls1 = html_tag('div', { :id => @id, :class => ['quoteblock', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; _slim_controls2 << ("<blockquote>".freeze); _slim_controls2 << ((content).to_s); 
      ; _slim_controls2 << ("</blockquote>".freeze); attribution = (attr? :attribution) ? (attr :attribution) : nil; 
      ; citetitle = (attr? :citetitle) ? (attr :citetitle) : nil; 
      ; if attribution || citetitle; 
      ; _slim_controls2 << ("<div class=\"attribution\">".freeze); 
      ; if citetitle; 
      ; _slim_controls2 << ("<cite>".freeze); _slim_controls2 << ((citetitle).to_s); 
      ; _slim_controls2 << ("</cite>".freeze); end; if attribution; 
      ; if citetitle; 
      ; _slim_controls2 << ("<br>".freeze); 
      ; end; _slim_controls2 << ("&#8212; ".freeze); _slim_controls2 << ((attribution).to_s); 
      ; end; _slim_controls2 << ("</div>".freeze); end; _slim_controls2; end; _buf << ((_slim_controls1).to_s); _buf
    end
  end

  def convert_video(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; 
      ; 
      ; no_stretch = ((attr? :width) || (attr? :height)); 
      ; width = (attr? :width) ? (attr :width) : "100%"; 
      ; height = (attr? :height) ? (attr :height) : "100%"; 
      ; 
      ; _slim_controls1 = html_tag('div', { :id => @id, :class => ['videoblock', @style, role, (no_stretch ? nil : 'stretch'), ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((captioned_title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; case attr :poster; 
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
      ; _slim_controls2 << ("<iframe".freeze); _slim_codeattributes1 = (width); if _slim_codeattributes1; if _slim_codeattributes1 == true; _slim_controls2 << (" width".freeze); else; _slim_controls2 << (" width=\"".freeze); _slim_controls2 << ((_slim_codeattributes1).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes2 = (height); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls2 << (" height".freeze); else; _slim_controls2 << (" height=\"".freeze); _slim_controls2 << ((_slim_codeattributes2).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes3 = src; if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" src".freeze); else; _slim_controls2 << (" src=\"".freeze); _slim_controls2 << ((_slim_codeattributes3).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes4 = 0; if _slim_codeattributes4; if _slim_codeattributes4 == true; _slim_controls2 << (" frameborder".freeze); else; _slim_controls2 << (" frameborder=\"".freeze); _slim_controls2 << ((_slim_codeattributes4).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_controls2 << (" webkitAllowFullScreen mozallowfullscreen allowFullScreen".freeze); _slim_codeattributes5 = (option? 'autoplay'); if _slim_codeattributes5; if _slim_codeattributes5 == true; _slim_controls2 << (" data-autoplay".freeze); else; _slim_controls2 << (" data-autoplay=\"".freeze); _slim_controls2 << ((_slim_codeattributes5).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes6 = ((option? 'autoplay') ? "autoplay" : nil); if _slim_codeattributes6; if _slim_codeattributes6 == true; _slim_controls2 << (" allow".freeze); else; _slim_controls2 << (" allow=\"".freeze); _slim_controls2 << ((_slim_codeattributes6).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_controls2 << ("></iframe>".freeze); 
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
      ; _slim_controls2 << ("<iframe".freeze); _slim_codeattributes7 = (width); if _slim_codeattributes7; if _slim_codeattributes7 == true; _slim_controls2 << (" width".freeze); else; _slim_controls2 << (" width=\"".freeze); _slim_controls2 << ((_slim_codeattributes7).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes8 = (height); if _slim_codeattributes8; if _slim_codeattributes8 == true; _slim_controls2 << (" height".freeze); else; _slim_controls2 << (" height=\"".freeze); _slim_controls2 << ((_slim_codeattributes8).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes9 = src; if _slim_codeattributes9; if _slim_codeattributes9 == true; _slim_controls2 << (" src".freeze); else; _slim_controls2 << (" src=\"".freeze); _slim_controls2 << ((_slim_codeattributes9).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes10 = 0; if _slim_codeattributes10; if _slim_codeattributes10 == true; _slim_controls2 << (" frameborder".freeze); else; _slim_controls2 << (" frameborder=\"".freeze); _slim_controls2 << ((_slim_codeattributes10).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes11 = !(option? 'nofullscreen'); if _slim_codeattributes11; if _slim_codeattributes11 == true; _slim_controls2 << (" allowfullscreen".freeze); else; _slim_controls2 << (" allowfullscreen=\"".freeze); _slim_controls2 << ((_slim_codeattributes11).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes12 = (option? 'autoplay'); if _slim_codeattributes12; if _slim_codeattributes12 == true; _slim_controls2 << (" data-autoplay".freeze); else; _slim_controls2 << (" data-autoplay=\"".freeze); _slim_controls2 << ((_slim_codeattributes12).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes13 = ((option? 'autoplay') ? "autoplay" : nil); if _slim_codeattributes13; if _slim_codeattributes13 == true; _slim_controls2 << (" allow".freeze); else; _slim_controls2 << (" allow=\"".freeze); _slim_controls2 << ((_slim_codeattributes13).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_controls2 << ("></iframe>".freeze); 
      ; else; 
      ; 
      ; 
      ; 
      ; _slim_controls2 << ("<video".freeze); _slim_codeattributes14 = media_uri(attr :target); if _slim_codeattributes14; if _slim_codeattributes14 == true; _slim_controls2 << (" src".freeze); else; _slim_controls2 << (" src=\"".freeze); _slim_controls2 << ((_slim_codeattributes14).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes15 = (width); if _slim_codeattributes15; if _slim_codeattributes15 == true; _slim_controls2 << (" width".freeze); else; _slim_controls2 << (" width=\"".freeze); _slim_controls2 << ((_slim_codeattributes15).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes16 = (height); if _slim_codeattributes16; if _slim_codeattributes16 == true; _slim_controls2 << (" height".freeze); else; _slim_controls2 << (" height=\"".freeze); _slim_controls2 << ((_slim_codeattributes16).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes17 = ((attr :poster) ? media_uri(attr :poster) : nil); if _slim_codeattributes17; if _slim_codeattributes17 == true; _slim_controls2 << (" poster".freeze); else; _slim_controls2 << (" poster=\"".freeze); _slim_controls2 << ((_slim_codeattributes17).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes18 = (option? 'autoplay'); if _slim_codeattributes18; if _slim_codeattributes18 == true; _slim_controls2 << (" data-autoplay".freeze); else; _slim_controls2 << (" data-autoplay=\"".freeze); _slim_controls2 << ((_slim_codeattributes18).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes19 = !(option? 'nocontrols'); if _slim_codeattributes19; if _slim_codeattributes19 == true; _slim_controls2 << (" controls".freeze); else; _slim_controls2 << (" controls=\"".freeze); _slim_controls2 << ((_slim_codeattributes19).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes20 = (option? 'loop'); if _slim_codeattributes20; if _slim_codeattributes20 == true; _slim_controls2 << (" loop".freeze); else; _slim_controls2 << (" loop=\"".freeze); _slim_controls2 << ((_slim_codeattributes20).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_controls2 << (">Your browser does not support the video tag.</video>".freeze); 
      ; 
      ; end; _slim_controls2; end; _buf << ((_slim_controls1).to_s); _buf
    end
  end

  def convert_thematic_break(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<hr>".freeze); 
      ; _buf
    end
  end

  def convert_preamble(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; 
      ; 
      ; _buf
    end
  end

  def convert_sidebar(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; if (has_role? 'aside') or (has_role? 'speaker') or (has_role? 'notes'); 
      ; _buf << ("<aside class=\"notes\">".freeze); _buf << ((resolve_content).to_s); 
      ; _buf << ("</aside>".freeze); 
      ; else; 
      ; _slim_controls1 = html_tag('div', { :id => @id, :class => ['sidebarblock', role, ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; _slim_controls2 << ("<div class=\"content\">".freeze); 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; _slim_controls2 << ((content).to_s); 
      ; _slim_controls2 << ("</div>".freeze); _slim_controls2; end; _buf << ((_slim_controls1).to_s); end; _buf
    end
  end

  def convert_listing(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; nowrap = (option? 'nowrap') || !(document.attr? 'prewrap'); 
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
      ; end; _slim_controls1 = html_tag('div', { :id => id, :class => ['listingblock', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes.reject {|key, _| key == 'data-id' }))) do; _slim_controls2 = ''; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((captioned_title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; _slim_controls2 << ("<div class=\"content\">".freeze); 
      ; if syntax_hl; 
      ; _slim_controls2 << (((syntax_hl.format self, lang, opts)).to_s); 
      ; else; 
      ; if @style == 'source'; 
      ; _slim_controls2 << ("<pre".freeze); _temple_html_attributeremover1 = ''; _slim_codeattributes1 = ['highlight', ('nowrap' if nowrap)]; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes1).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\"".freeze); _slim_controls2 << ((_temple_html_attributeremover1).to_s); _slim_controls2 << ("\"".freeze); end; _slim_controls2 << ("><code".freeze); 
      ; _temple_html_attributeremover2 = ''; _slim_codeattributes2 = [("language-#{lang}" if lang)]; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover2 << ((_slim_codeattributes2.join(" ")).to_s); else; _temple_html_attributeremover2 << ((_slim_codeattributes2).to_s); end; _temple_html_attributeremover2; if !_temple_html_attributeremover2.empty?; _slim_controls2 << (" class=\"".freeze); _slim_controls2 << ((_temple_html_attributeremover2).to_s); _slim_controls2 << ("\"".freeze); end; _slim_codeattributes3 = ("#{lang}" if lang); if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" data-lang".freeze); else; _slim_controls2 << (" data-lang=\"".freeze); _slim_controls2 << ((_slim_codeattributes3).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_controls2 << (">".freeze); 
      ; _slim_controls2 << ((content || '').to_s); 
      ; _slim_controls2 << ("</code></pre>".freeze); else; 
      ; _slim_controls2 << ("<pre".freeze); _temple_html_attributeremover3 = ''; _slim_codeattributes4 = [('nowrap' if nowrap)]; if Array === _slim_codeattributes4; _slim_codeattributes4 = _slim_codeattributes4.flatten; _slim_codeattributes4.map!(&:to_s); _slim_codeattributes4.reject!(&:empty?); _temple_html_attributeremover3 << ((_slim_codeattributes4.join(" ")).to_s); else; _temple_html_attributeremover3 << ((_slim_codeattributes4).to_s); end; _temple_html_attributeremover3; if !_temple_html_attributeremover3.empty?; _slim_controls2 << (" class=\"".freeze); _slim_controls2 << ((_temple_html_attributeremover3).to_s); _slim_controls2 << ("\"".freeze); end; _slim_controls2 << (">".freeze); 
      ; _slim_controls2 << ((content || '').to_s); 
      ; _slim_controls2 << ("</pre>".freeze); end; end; _slim_controls2 << ("</div>".freeze); _slim_controls2; end; _buf << ((_slim_controls1).to_s); _buf
    end
  end

  def convert_inline_indexterm(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; if @type == :visible; 
      ; _buf << ((@text).to_s); 
      ; end; _buf
    end
  end

  def convert_olist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _slim_controls1 = html_tag('div', { :id => @id, :class => ['olist', @style, role] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; _slim_controls2 << ("<ol".freeze); _temple_html_attributeremover1 = ''; _slim_codeattributes1 = @style; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes1).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\"".freeze); _slim_controls2 << ((_temple_html_attributeremover1).to_s); _slim_controls2 << ("\"".freeze); end; _slim_codeattributes2 = (attr :start); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls2 << (" start".freeze); else; _slim_controls2 << (" start=\"".freeze); _slim_controls2 << ((_slim_codeattributes2).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes3 = list_marker_keyword; if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" type".freeze); else; _slim_controls2 << (" type=\"".freeze); _slim_controls2 << ((_slim_codeattributes3).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_controls2 << (">".freeze); 
      ; items.each do |item|; 
      ; _slim_controls2 << ("<li".freeze); _temple_html_attributeremover2 = ''; _slim_codeattributes4 = ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step')); if Array === _slim_codeattributes4; _slim_codeattributes4 = _slim_codeattributes4.flatten; _slim_codeattributes4.map!(&:to_s); _slim_codeattributes4.reject!(&:empty?); _temple_html_attributeremover2 << ((_slim_codeattributes4.join(" ")).to_s); else; _temple_html_attributeremover2 << ((_slim_codeattributes4).to_s); end; _temple_html_attributeremover2; if !_temple_html_attributeremover2.empty?; _slim_controls2 << (" class=\"".freeze); _slim_controls2 << ((_temple_html_attributeremover2).to_s); _slim_controls2 << ("\"".freeze); end; _slim_controls2 << ("><p>".freeze); 
      ; _slim_controls2 << ((item.text).to_s); 
      ; _slim_controls2 << ("</p>".freeze); if item.blocks?; 
      ; _slim_controls2 << ((item.content).to_s); 
      ; end; _slim_controls2 << ("</li>".freeze); end; _slim_controls2 << ("</ol>".freeze); _slim_controls2; end; _buf << ((_slim_controls1).to_s); _buf
    end
  end

  def convert_pass(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ((content).to_s); 
      ; _buf
    end
  end

  def convert_colist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _slim_controls1 = html_tag('div', { :id => @id, :class => ['colist', @style, role] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; if @document.attr? :icons; 
      ; font_icons = @document.attr? :icons, 'font'; 
      ; _slim_controls2 << ("<table>".freeze); 
      ; items.each_with_index do |item, i|; 
      ; num = i + 1; 
      ; _slim_controls2 << ("<tr".freeze); _temple_html_attributeremover1 = ''; _slim_codeattributes1 = ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step')); if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes1).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\"".freeze); _slim_controls2 << ((_temple_html_attributeremover1).to_s); _slim_controls2 << ("\"".freeze); end; _slim_controls2 << ("><td>".freeze); 
      ; 
      ; if font_icons; 
      ; _slim_controls2 << ("<i class=\"conum\"".freeze); _slim_codeattributes2 = num; if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls2 << (" data-value".freeze); else; _slim_controls2 << (" data-value=\"".freeze); _slim_controls2 << ((_slim_codeattributes2).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_controls2 << ("></i><b>".freeze); 
      ; _slim_controls2 << ((num).to_s); 
      ; _slim_controls2 << ("</b>".freeze); else; 
      ; _slim_controls2 << ("<img".freeze); _slim_codeattributes3 = icon_uri("callouts/#{num}"); if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" src".freeze); else; _slim_controls2 << (" src=\"".freeze); _slim_controls2 << ((_slim_codeattributes3).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_codeattributes4 = num; if _slim_codeattributes4; if _slim_codeattributes4 == true; _slim_controls2 << (" alt".freeze); else; _slim_controls2 << (" alt=\"".freeze); _slim_controls2 << ((_slim_codeattributes4).to_s); _slim_controls2 << ("\"".freeze); end; end; _slim_controls2 << (">".freeze); 
      ; end; _slim_controls2 << ("</td><td>".freeze); _slim_controls2 << ((item.text).to_s); 
      ; _slim_controls2 << ("</td></tr>".freeze); end; _slim_controls2 << ("</table>".freeze); else; 
      ; _slim_controls2 << ("<ol>".freeze); 
      ; items.each do |item|; 
      ; _slim_controls2 << ("<li".freeze); _temple_html_attributeremover2 = ''; _slim_codeattributes5 = ('fragment' if (option? :step) || (has_role? 'step') || (attr? 'step')); if Array === _slim_codeattributes5; _slim_codeattributes5 = _slim_codeattributes5.flatten; _slim_codeattributes5.map!(&:to_s); _slim_codeattributes5.reject!(&:empty?); _temple_html_attributeremover2 << ((_slim_codeattributes5.join(" ")).to_s); else; _temple_html_attributeremover2 << ((_slim_codeattributes5).to_s); end; _temple_html_attributeremover2; if !_temple_html_attributeremover2.empty?; _slim_controls2 << (" class=\"".freeze); _slim_controls2 << ((_temple_html_attributeremover2).to_s); _slim_controls2 << ("\"".freeze); end; _slim_controls2 << ("><p>".freeze); 
      ; _slim_controls2 << ((item.text).to_s); 
      ; _slim_controls2 << ("</p></li>".freeze); end; _slim_controls2 << ("</ol>".freeze); end; _slim_controls2; end; _buf << ((_slim_controls1).to_s); _buf
    end
  end

  def convert_stretch_nested_elements(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<script>var dom = {};\ndom.slides = document.querySelector('.reveal .slides');\n\nfunction getRemainingHeight(element, slideElement, height) {\n  height = height || 0;\n  if (element) {\n    var newHeight, oldHeight = element.style.height;\n    // Change the .stretch element height to 0 in order find the height of all\n    // the other elements\n    element.style.height = '0px';\n    // In Overview mode, the parent (.slide) height is set of 700px.\n    // Restore it temporarily to its natural height.\n    slideElement.style.height = 'auto';\n    newHeight = height - slideElement.offsetHeight;\n    // Restore the old height, just in case\n    element.style.height = oldHeight + 'px';\n    // Clear the parent (.slide) height. .removeProperty works in IE9+\n    slideElement.style.removeProperty('height');\n    return newHeight;\n  }\n  return height;\n}\n\nfunction layoutSlideContents(width, height) {\n  // Handle sizing of elements with the 'stretch' class\n  toArray(dom.slides.querySelectorAll('section .stretch')).forEach(function (element) {\n    // Determine how much vertical space we can use\n    var limit = 5; // hard limit\n    var parent = element.parentNode;\n    while (parent.nodeName !== 'SECTION' && limit > 0) {\n      parent = parent.parentNode;\n      limit--;\n    }\n    if (limit === 0) {\n      // unable to find parent, aborting!\n      return;\n    }\n    var remainingHeight = getRemainingHeight(element, parent, height);\n    // Consider the aspect ratio of media elements\n    if (/(img|video)/gi.test(element.nodeName)) {\n      var nw = element.naturalWidth || element.videoWidth, nh = element.naturalHeight || element.videoHeight;\n      var es = Math.min(width / nw, remainingHeight / nh);\n      element.style.width = (nw * es) + 'px';\n      element.style.height = (nh * es) + 'px';\n    } else {\n      element.style.width = width + 'px';\n      element.style.height = remainingHeight + 'px';\n    }\n  });\n}\n\nfunction toArray(o) {\n  return Array.prototype.slice.call(o);\n}\n\nReveal.addEventListener('slidechanged', function () {\n  layoutSlideContents(".freeze); 
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
      ; _buf << ((attr 'revealjs_width', 960).to_s); _buf << (", ".freeze); _buf << ((attr 'revealjs_height', 700).to_s); _buf << (")\n});\nReveal.addEventListener('ready', function () {\n  layoutSlideContents(".freeze); 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_width', 960).to_s); _buf << (", ".freeze); _buf << ((attr 'revealjs_height', 700).to_s); _buf << (")\n});\nReveal.addEventListener('resize', function () {\n  layoutSlideContents(".freeze); 
      ; 
      ; 
      ; _buf << ((attr 'revealjs_width', 960).to_s); _buf << (", ".freeze); _buf << ((attr 'revealjs_height', 700).to_s); _buf << (")\n});</script>".freeze); 
      ; 
      ; _buf
    end
  end

  def convert_section(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; 
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
      ; _buf << ("<div class=\"footnotes\">".freeze); 
      ; slide_footnotes.each do |footnote|; 
      ; _buf << ("<div class=\"footnote\">".freeze); 
      ; _buf << (("#{footnote.index}. #{footnote.text}").to_s); 
      ; 
      ; _buf << ("</div>".freeze); end; _buf << ("</div>".freeze); end; end; content_for :section do; 
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
      ; _buf << ("<section".freeze); _slim_codeattributes1 = (titleless ? nil : id); if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id".freeze); else; _buf << (" id=\"".freeze); _buf << ((_slim_codeattributes1).to_s); _buf << ("\"".freeze); end; end; _temple_html_attributeremover1 = ''; _slim_codeattributes2 = roles; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes2.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes2).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _buf << (" class=\"".freeze); _buf << ((_temple_html_attributeremover1).to_s); _buf << ("\"".freeze); end; _slim_codeattributes3 = (attr "background-gradient"); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" data-background-gradient".freeze); else; _buf << (" data-background-gradient=\"".freeze); _buf << ((_slim_codeattributes3).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes4 = (attr 'transition'); if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" data-transition".freeze); else; _buf << (" data-transition=\"".freeze); _buf << ((_slim_codeattributes4).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes5 = (attr 'transition-speed'); if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" data-transition-speed".freeze); else; _buf << (" data-transition-speed=\"".freeze); _buf << ((_slim_codeattributes5).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes6 = data_background_color; if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" data-background-color".freeze); else; _buf << (" data-background-color=\"".freeze); _buf << ((_slim_codeattributes6).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes7 = data_background_image; if _slim_codeattributes7; if _slim_codeattributes7 == true; _buf << (" data-background-image".freeze); else; _buf << (" data-background-image=\"".freeze); _buf << ((_slim_codeattributes7).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes8 = (data_background_size || attr('background-size')); if _slim_codeattributes8; if _slim_codeattributes8 == true; _buf << (" data-background-size".freeze); else; _buf << (" data-background-size=\"".freeze); _buf << ((_slim_codeattributes8).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes9 = (data_background_repeat || attr('background-repeat')); if _slim_codeattributes9; if _slim_codeattributes9 == true; _buf << (" data-background-repeat".freeze); else; _buf << (" data-background-repeat=\"".freeze); _buf << ((_slim_codeattributes9).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes10 = (data_background_transition || attr('background-transition')); if _slim_codeattributes10; if _slim_codeattributes10 == true; _buf << (" data-background-transition".freeze); else; _buf << (" data-background-transition=\"".freeze); _buf << ((_slim_codeattributes10).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes11 = (data_background_position || attr('background-position')); if _slim_codeattributes11; if _slim_codeattributes11 == true; _buf << (" data-background-position".freeze); else; _buf << (" data-background-position=\"".freeze); _buf << ((_slim_codeattributes11).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes12 = (attr "background-iframe"); if _slim_codeattributes12; if _slim_codeattributes12 == true; _buf << (" data-background-iframe".freeze); else; _buf << (" data-background-iframe=\"".freeze); _buf << ((_slim_codeattributes12).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes13 = data_background_video; if _slim_codeattributes13; if _slim_codeattributes13 == true; _buf << (" data-background-video".freeze); else; _buf << (" data-background-video=\"".freeze); _buf << ((_slim_codeattributes13).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes14 = ((attr? 'background-video-loop') || (option? 'loop')); if _slim_codeattributes14; if _slim_codeattributes14 == true; _buf << (" data-background-video-loop".freeze); else; _buf << (" data-background-video-loop=\"".freeze); _buf << ((_slim_codeattributes14).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes15 = ((attr? 'background-video-muted') || (option? 'muted')); if _slim_codeattributes15; if _slim_codeattributes15 == true; _buf << (" data-background-video-muted".freeze); else; _buf << (" data-background-video-muted=\"".freeze); _buf << ((_slim_codeattributes15).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes16 = (attr "background-opacity"); if _slim_codeattributes16; if _slim_codeattributes16 == true; _buf << (" data-background-opacity".freeze); else; _buf << (" data-background-opacity=\"".freeze); _buf << ((_slim_codeattributes16).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes17 = (attr "autoslide"); if _slim_codeattributes17; if _slim_codeattributes17 == true; _buf << (" data-autoslide".freeze); else; _buf << (" data-autoslide=\"".freeze); _buf << ((_slim_codeattributes17).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes18 = (attr 'state'); if _slim_codeattributes18; if _slim_codeattributes18 == true; _buf << (" data-state".freeze); else; _buf << (" data-state=\"".freeze); _buf << ((_slim_codeattributes18).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes19 = ((attr? 'auto-animate') || (option? 'auto-animate')); if _slim_codeattributes19; if _slim_codeattributes19 == true; _buf << (" data-auto-animate".freeze); else; _buf << (" data-auto-animate=\"".freeze); _buf << ((_slim_codeattributes19).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes20 = ((attr 'auto-animate-easing') || (option? 'auto-animate-easing')); if _slim_codeattributes20; if _slim_codeattributes20 == true; _buf << (" data-auto-animate-easing".freeze); else; _buf << (" data-auto-animate-easing=\"".freeze); _buf << ((_slim_codeattributes20).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes21 = ((attr 'auto-animate-unmatched') || (option? 'auto-animate-unmatched')); if _slim_codeattributes21; if _slim_codeattributes21 == true; _buf << (" data-auto-animate-unmatched".freeze); else; _buf << (" data-auto-animate-unmatched=\"".freeze); _buf << ((_slim_codeattributes21).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes22 = ((attr 'auto-animate-duration') || (option? 'auto-animate-duration')); if _slim_codeattributes22; if _slim_codeattributes22 == true; _buf << (" data-auto-animate-duration".freeze); else; _buf << (" data-auto-animate-duration=\"".freeze); _buf << ((_slim_codeattributes22).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes23 = (attr 'auto-animate-id'); if _slim_codeattributes23; if _slim_codeattributes23 == true; _buf << (" data-auto-animate-id".freeze); else; _buf << (" data-auto-animate-id=\"".freeze); _buf << ((_slim_codeattributes23).to_s); _buf << ("\"".freeze); end; end; _slim_codeattributes24 = ((attr? 'auto-animate-restart') || (option? 'auto-animate-restart')); if _slim_codeattributes24; if _slim_codeattributes24 == true; _buf << (" data-auto-animate-restart".freeze); else; _buf << (" data-auto-animate-restart=\"".freeze); _buf << ((_slim_codeattributes24).to_s); _buf << ("\"".freeze); end; end; _buf << (">".freeze); 
      ; unless hide_title; 
      ; _buf << ("<h2>".freeze); _buf << ((section_title).to_s); 
      ; _buf << ("</h2>".freeze); end; if parent_section_with_vertical_slides; 
      ; unless (_blocks = blocks - vertical_slides).empty?; 
      ; _buf << ("<div class=\"slide-content\">".freeze); 
      ; _blocks.each do |block|; 
      ; _buf << ((block.convert).to_s); 
      ; end; _buf << ("</div>".freeze); end; yield_content :footnotes; 
      ; 
      ; else; 
      ; unless (_content = content.chomp).empty?; 
      ; _buf << ("<div class=\"slide-content\">".freeze); 
      ; _buf << ((_content).to_s); 
      ; _buf << ("</div>".freeze); end; yield_content :footnotes; 
      ; 
      ; end; clear_slide_footnotes; 
      ; 
      ; _buf << ("</section>".freeze); 
      ; 
      ; end; if parent_section_with_vertical_slides; 
      ; _buf << ("<section>".freeze); 
      ; yield_content :section; 
      ; vertical_slides.each do |subsection|; 
      ; _buf << ((subsection.convert).to_s); 
      ; 
      ; end; _buf << ("</section>".freeze); 
      ; else; 
      ; if @level >= 3; 
      ; 
      ; _slim_htag_filter1 = ((@level)).to_s; _buf << ("<h".freeze); _buf << ((_slim_htag_filter1).to_s); _buf << (">".freeze); _buf << ((title).to_s); 
      ; _buf << ("</h".freeze); _buf << ((_slim_htag_filter1).to_s); _buf << (">".freeze); _buf << ((content.chomp).to_s); 
      ; else; 
      ; yield_content :section; 
      ; end; end; _buf
    end
  end

  def convert_inline_image(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _slim_controls1 = html_tag('span', { :class => [@type, role, ('fragment' if (option? :step) || (attr? 'step'))], :style => ("float: #{attr :float}" if attr? :float) }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; _slim_controls2 << ((convert_inline_image).to_s); 
      ; _slim_controls2; end; _buf << ((_slim_controls1).to_s); _buf
    end
  end

  def convert_example(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _slim_controls1 = html_tag('div', { :id => @id, :class => ['exampleblock', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((captioned_title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; _slim_controls2 << ("<div class=\"content\">".freeze); _slim_controls2 << ((content).to_s); 
      ; _slim_controls2 << ("</div>".freeze); _slim_controls2; end; _buf << ((_slim_controls1).to_s); _buf
    end
  end

  def convert_inline_break(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ((@text).to_s); 
      ; _buf << ("<br>".freeze); 
      ; _buf
    end
  end

  def convert_literal(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _slim_controls1 = html_tag('div', { :id => id, :class => ['literalblock', role, ('fragment' if (option? :step) || (attr? 'step'))] }.merge(data_attrs(@attributes))) do; _slim_controls2 = ''; 
      ; if title?; 
      ; _slim_controls2 << ("<div class=\"title\">".freeze); _slim_controls2 << ((title).to_s); 
      ; _slim_controls2 << ("</div>".freeze); end; _slim_controls2 << ("<div class=\"content\"><pre".freeze); _temple_html_attributeremover1 = ''; _slim_codeattributes1 = (!(@document.attr? :prewrap) || (option? 'nowrap') ? 'nowrap' : nil); if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << ((_slim_codeattributes1.join(" ")).to_s); else; _temple_html_attributeremover1 << ((_slim_codeattributes1).to_s); end; _temple_html_attributeremover1; if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\"".freeze); _slim_controls2 << ((_temple_html_attributeremover1).to_s); _slim_controls2 << ("\"".freeze); end; _slim_controls2 << (">".freeze); _slim_controls2 << ((content).to_s); 
      ; _slim_controls2 << ("</pre></div>".freeze); _slim_controls2; end; _buf << ((_slim_controls1).to_s); _buf
    end
  end

  def convert_page_break(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      converter.set_local_variables(binding, opts) unless opts.empty?
      _buf = ''; _buf << ("<div style=\"page-break-after: always;\"></div>".freeze); 
      ; _buf
    end
  end
  #------------------ End of generated transformation methods ------------------#

  def set_local_variables(binding, vars)
    vars.each do |key, val|
      binding.local_variable_set(key.to_sym, val)
    end
  end

end
