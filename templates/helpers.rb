unless RUBY_ENGINE == 'opal'
  # This helper file borrows from the Bespoke converter
  # https://github.com/asciidoctor/asciidoctor-bespoke
  require 'asciidoctor'
end

require 'json'

# This module gets mixed in to every node (the context of the template) at the
# time the node is being converted. The properties and methods in this module
# effectively become direct members of the template.
module Slim::Helpers

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
