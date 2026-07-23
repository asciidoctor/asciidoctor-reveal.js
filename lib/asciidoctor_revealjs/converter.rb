# frozen_string_literal: true

require 'asciidoctor'
require 'json'

module Asciidoctor
  # Reveal.js module
  module Revealjs
    # Reveal.js converter
    class Converter < ::Asciidoctor::Converter::Base
      SLICE_HINT_RX = /  +/.freeze

      # Defaults (from the asciidoctor-html5s project).
      DEFAULT_TOCLEVELS = 2
      DEFAULT_SECTNUMLEVELS = 3

      STEM_EQNUMS_AMS = 'ams'
      STEM_EQNUMS_NONE = 'none'
      STEM_EQNUMS_VALID_VALUES = [
        STEM_EQNUMS_NONE,
        STEM_EQNUMS_AMS,
        'all'
      ].freeze

      MATHJAX_VERSION = '3.2.0'

      # Footnotes
      module Footnotes
        module_function

        ##
        # Display footnotes per slide
        #
        @slide_footnotes = {}
        @section_footnotes = {}.compare_by_identity

        def slide_footnote(footnote)
          footnote_parent = footnote.parent
          # footnotes declared on the section title are processed during the parsing/substitution.
          # as a result, we need to store them to display them on the right slide/section
          if footnote_parent.instance_of?(::Asciidoctor::Section)
            section_footnotes = @section_footnotes[footnote_parent] || []
            footnote_index = section_footnotes.length + 1
            attributes = footnote.attributes.merge({ 'index' => footnote_index })
            inline_footnote = Asciidoctor::Inline.new(footnote_parent, footnote.context, footnote.text, attributes: attributes)
            section_footnotes << Asciidoctor::Document::Footnote.new(inline_footnote.attr(:index), inline_footnote.id, inline_footnote.text)
            @section_footnotes[footnote_parent] = section_footnotes
          else
            parent = footnote.parent
            parent = parent.parent until parent.nil? || parent.instance_of?(::Asciidoctor::Section)
            # check if there is any footnote attached on the section title
            section_footnotes = parent.nil? ? [] : @section_footnotes[parent] || []
            initial_index = footnote.attr(:index)
            # reset the footnote numbering to 1 on each slide
            # make sure that if a footnote is used more than once it will use the same index/number
            slide_index = (existing_footnote = @slide_footnotes[initial_index]) ? existing_footnote.index : @slide_footnotes.length + section_footnotes.length + 1
            attributes = footnote.attributes.merge({ 'index' => slide_index })
            inline_footnote = Asciidoctor::Inline.new(footnote_parent, footnote.context, footnote.text, attributes: attributes)
            @slide_footnotes[initial_index] = Asciidoctor::Document::Footnote.new(inline_footnote.attr(:index), inline_footnote.id, inline_footnote.text)
          end
          inline_footnote
        end

        def clear_slide_footnotes
          @slide_footnotes = {}
        end

        def slide_footnotes(section)
          section_footnotes = @section_footnotes[section] || []
          section_footnotes + @slide_footnotes.values
        end
      end

      register_for 'revealjs', 'reveal.js'

      def initialize(backend, opts = {})
        super
        basebackend 'html' if respond_to? :basebackend
        outfilesuffix '.html' if respond_to? :outfilesuffix
        filetype 'html' if respond_to? :filetype
        supports_templates if respond_to? :supports_templates

        delegate_backend = (opts[:delegate_backend] || 'html5').to_s
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

      def convert_admonition(node, _opts = {})
        if (node.has_role? 'aside') || (node.has_role? 'speaker') || (node.has_role? 'notes')
          %(<aside class="notes">#{resolve_content(node)}</aside>)
        else
          attrs = attributes({ id: node.id,
                               class: ['admonitionblock', (node.attr :name), node.role, ('fragment' if step?(node))] }.merge(data_attrs(node.attributes)))
          icon = if node.document.attr? :icons, 'font'
                   icon_mapping = { 'caution' => 'fire', 'important' => 'exclamation-circle', 'note' => 'info-circle', 'tip' => 'lightbulb-o',
                                    'warning' => 'warning' }
                   %(<i#{attributes(class: %(fa fa-#{icon_mapping[node.attr :name]}), title: (node.attr :textlabel || node.caption))}></i>)
                 elsif node.document.attr? :icons
                   %(<img#{attributes(src: node.icon_uri(node.attr(:name)), alt: node.caption)}>)
                 else
                   %(<div class="title">#{(node.attr :textlabel) || node.caption}</div>)
                 end
          cell = +''
          cell << %(<div class="title">#{node.title}</div>) if node.title?
          cell << node.content.to_s
          %(<div#{attrs}><table><tr><td class="icon">#{icon}</td><td class="content">#{cell}</td></tr></table></div>)
        end
      end

      def convert_audio(node, _opts = {})
        attrs = attributes({ id: node.id, class: ['audioblock', node.style, node.role] }.merge(data_attrs(node.attributes)))
        buf = +''
        buf << %(<div class="title">#{node.captioned_title}</div>) if node.title?
        buf << %(<div class="content">)
        buf << %(<audio#{attributes(src: node.media_uri(node.attr(:target)), autoplay: (node.option? 'autoplay'), controls: !(node.option? 'nocontrols'),
                                    loop: (node.option? 'loop'))}>Your browser does not support the audio tag.</audio>)
        buf << %(</div>)
        %(<div#{attrs}>#{buf}</div>)
      end

      def convert_colist(node, _opts = {})
        attrs = attributes({ id: node.id, class: ['colist', node.style, node.role] }.merge(data_attrs(node.attributes)))
        buf = +''
        buf << %(<div class="title">#{node.title}</div>) if node.title?
        if node.document.attr? :icons
          font_icons = node.document.attr? :icons, 'font'
          buf << '<table>'
          node.items.each_with_index do |item, i|
            num = i + 1
            cell = +'<td>'
            if font_icons
              cell << %(<i#{attributes(class: 'conum', 'data-value' => num)}></i>)
              cell << %(<b>#{num}</b>)
            else
              cell << %(<img#{attributes(src: node.icon_uri("callouts/#{num}"), alt: num)}>)
            end
            cell << %(</td><td>#{item.text}</td>)
            buf << %(<tr#{attributes(class: ('fragment' if step_or_role?(node)))}>#{cell}</tr>)
          end
          buf << '</table>'
        else
          buf << '<ol>'
          node.items.each do |item|
            buf << %(<li#{attributes(class: ('fragment' if step_or_role?(node)))}><p>#{item.text}</p></li>)
          end
          buf << '</ol>'
        end
        %(<div#{attrs}>#{buf}</div>)
      end

      def convert_dlist(node, _opts = {})
        case node.style
        when 'qanda'
          attrs = attributes({ id: node.id, class: ['qlist', node.style, node.role] }.merge(data_attrs(node.attributes)))
          buf = +''
          buf << %(<div class="title">#{node.title}</div>) if node.title?
          buf << '<ol>'
          node.items.each do |questions, answer|
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
        when 'horizontal'
          attrs = attributes({ id: node.id, class: ['hdlist', node.role] }.merge(data_attrs(node.attributes)))
          buf = +''
          buf << %(<div class="title">#{node.title}</div>) if node.title?
          buf << '<table>'
          if (node.attr? :labelwidth) || (node.attr? :itemwidth)
            buf << '<colgroup>'
            buf << %(<col#{attributes(style: (node.attr?(:labelwidth) ? %(width:#{(node.attr :labelwidth).chomp '%'}%;) : nil))}>)
            buf << %(<col#{attributes(style: (node.attr?(:itemwidth) ? %(width:#{(node.attr :itemwidth).chomp '%'}%;) : nil))}>)
            buf << '</colgroup>'
          end
          node.items.each do |terms, dd|
            buf << '<tr>'
            cell = +''
            terms = [*terms]
            last_term = terms.last
            terms.each do |dt|
              cell << dt.text.to_s
              cell << '<br>' if dt != last_term
            end
            buf << %(<td#{attributes(class: ['hdlist1', ('strong' if node.option? 'strong')])}>#{cell}</td>)
            buf << '<td class="hdlist2">'
            unless dd.nil?
              buf << %(<p>#{dd.text}</p>) if dd.text?
              buf << dd.content.to_s if dd.blocks?
            end
            buf << '</td></tr>'
          end
          buf << '</table>'
        else
          attrs = attributes({ id: node.id, class: ['dlist', node.style, node.role] }.merge(data_attrs(node.attributes)))
          buf = +''
          buf << %(<div class="title">#{node.title}</div>) if node.title?
          buf << '<dl>'
          node.items.each do |terms, dd|
            [*terms].each do |dt|
              buf << %(<dt#{attributes(class: ('hdlist1' unless node.style))}>#{dt.text}</dt>)
            end
            next if dd.nil?

            buf << '<dd>'
            buf << %(<p>#{dd.text}</p>) if dd.text?
            buf << dd.content.to_s if dd.blocks?
            buf << '</dd>'
          end
          buf << '</dl>'
        end
        %(<div#{attrs}>#{buf}</div>)
      end

      def convert_embedded(node, _opts = {})
        buf = +''
        buf << %(<h1#{attributes(id: node.id)}>#{node.header.title}</h1>) unless node.notitle || !node.has_header?
        buf << node.content.to_s
        unless !node.footnotes? || node.attr?(:nofootnotes)
          buf << %(<div id="footnotes"><hr>)
          node.footnotes.each do |fn|
            buf << %(<div class="footnote" id="_footnote_#{fn.index}"><a href="#_footnoteref_#{fn.index}">#{fn.index}</a>. #{fn.text}</div>)
          end
          buf << %(</div>)
        end
        buf
      end

      def convert_example(node, _opts = {})
        attrs = attributes({ id: node.id, class: ['exampleblock', node.role, ('fragment' if step?(node))] }.merge(data_attrs(node.attributes)))
        buf = +''
        buf << %(<div class="title">#{node.captioned_title}</div>) if node.title?
        buf << %(<div class="content">#{node.content}</div>)
        %(<div#{attrs}>#{buf}</div>)
      end

      def convert_floating_title(node, _opts = {})
        %(<h#{node.level + 1}#{attributes(id: node.id, class: [node.style, node.role])}>#{node.title}</h#{node.level + 1}>)
      end

      def convert_image(node, _opts = {})
        return '' if %w[background canvas].include?(node.attributes[1])

        inline_style = [("text-align: #{node.attr :align}" if node.attr? :align), ("float: #{node.attr :float}" if node.attr? :float)].compact.join('; ')
        attrs = attributes({ id: node.id, class: ['imageblock', node.role, ('fragment' if step?(node))],
                             style: inline_style }.merge(data_attrs(node.attributes)))
        buf = +%(<div#{attrs}>#{image_content(node)}</div>)
        buf << %(<div class="title">#{node.captioned_title}</div>) if node.title?
        buf
      end

      def convert_inline_anchor(node, _opts = {})
        case node.type
        when :xref
          refid = (node.attr :refid) || node.target
          attrs = attributes({ href: node.target, class: [node.role, ('fragment' if step?(node))].compact }.merge(data_attrs(node.attributes)))
          %(<a#{attrs}>#{(node.text || node.document.references[:ids].fetch(refid, "[#{refid}]")).tr_s("\n", ' ')}</a>)
        when :ref
          %(<a#{attributes({ id: node.target }.merge(data_attrs(node.attributes)))}></a>)
        when :bibref
          %(<a#{attributes({ id: node.target }.merge(data_attrs(node.attributes)))}></a>[#{node.target}])
        else
          attrs = attributes({ :href => node.target, :class => [node.role, ('fragment' if step?(node))].compact, :target => (node.attr :window),
                               'data-preview-link' => bool_data_attr(node, :preview) }.merge(data_attrs(node.attributes)))
          %(<a#{attrs}>#{node.text}</a>)
        end
      end

      def convert_inline_break(node, _opts = {})
        %(#{node.text}<br>)
      end

      def convert_inline_button(node, _opts = {})
        %(<b#{attributes({ class: ['button'] }.merge(data_attrs(node.attributes)))}>#{node.text}</b>)
      end

      def convert_inline_callout(node, _opts = {})
        if node.document.attr? :icons, 'font'
          %(<i#{attributes(class: 'conum', 'data-value' => node.text)}></i><b>(#{node.text})</b>)
        elsif node.document.attr? :icons
          %(<img#{attributes(src: node.icon_uri("callouts/#{node.text}"), alt: node.text)}>)
        else
          %(<b>(#{node.text})</b>)
        end
      end

      def convert_inline_footnote(node, _opts = {})
        footnote = Footnotes.slide_footnote(node)
        index = footnote.attr(:index)
        id = footnote.id
        if node.type == :xref
          %(<sup#{attributes({ class: ['footnoteref'] }.merge(data_attrs(footnote.attributes)))}>[<span class="footnote" title="View footnote.">#{index}</span>]</sup>)
        else
          %(<sup#{attributes({ id: ("_footnote_#{id}" if id),
                               class: ['footnote'] }.merge(data_attrs(footnote.attributes)))}>[<span class="footnote" title="View footnote.">#{index}</span>]</sup>)
        end
      end

      def convert_inline_image(node, _opts = {})
        attrs = attributes({ class: [node.type, node.role, ('fragment' if step?(node))],
                             style: ("float: #{node.attr :float}" if node.attr? :float) }.merge(data_attrs(node.attributes)))
        %(<span#{attrs}>#{inline_image_content(node)}</span>)
      end

      def convert_inline_indexterm(node, _opts = {})
        node.type == :visible ? node.text : ''
      end

      def convert_inline_kbd(node, _opts = {})
        if (keys = node.attr 'keys').size == 1
          %(<kbd#{attributes(data_attrs(node.attributes))}>#{keys.first}</kbd>)
        else
          buf = +''
          keys.each_with_index do |key, idx|
            buf << '+' unless idx.zero?
            buf << %(<kbd>#{key}</kbd>)
          end
          %(<span#{attributes({ class: ['keyseq'] }.merge(data_attrs(node.attributes)))}>#{buf}</span>)
        end
      end

      def convert_inline_menu(node, _opts = {})
        menu = node.attr 'menu'
        menuitem = node.attr 'menuitem'
        if !(submenus = node.attr 'submenus').empty?
          content = %(<span class="menu">#{menu}</span>&#160;&#9656;&#32;) +
                    submenus.map { |submenu| %(<span class="submenu">#{submenu}</span>&#160;&#9656;&#32;) }.join +
                    %(<span class="menuitem">#{menuitem}</span>)
          %(<span#{attributes({ class: ['menuseq'] }.merge(data_attrs(node.attributes)))}>#{content}</span>)
        elsif !menuitem.nil?
          %(<span#{attributes({ class: ['menuseq'] }.merge(data_attrs(node.attributes)))}><span class="menu">#{menu}</span>&#160;&#9656;&#32;<span class="menuitem">#{menuitem}</span></span>)
        else
          %(<span#{attributes({ class: ['menu'] }.merge(data_attrs(node.attributes)))}>#{menu}</span>)
        end
      end

      def convert_inline_quoted(node, _opts = {})
        quote_tags = { emphasis: 'em', strong: 'strong', monospaced: 'code', superscript: 'sup', subscript: 'sub' }
        if (quote_tag = quote_tags[node.type])
          %(<#{quote_tag}#{attributes({ id: node.id,
                                        class: [node.role,
                                                ('fragment' if step?(node))].compact }.merge(data_attrs(node.attributes)))}>#{node.text}</#{quote_tag}>)
        else
          case node.type
          when :double
            inline_text_container(node, "&#8220;#{node.text}&#8221;")
          when :single
            inline_text_container(node, "&#8216;#{node.text}&#8217;")
          when :asciimath, :latexmath
            open, close = Asciidoctor::INLINE_MATH_DELIMITERS[node.type]
            inline_text_container(node, "#{open}#{node.text}#{close}")
          else
            inline_text_container(node, node.text)
          end
        end
      end

      def convert_listing(node, _opts = {})
        nowrap = (node.option? 'nowrap') || !(node.document.attr? 'prewrap')
        if node.style == 'source'
          syntax_hl = node.document.syntax_highlighter
          lang = node.attr :language
          if syntax_hl
            doc_attrs = node.document.attributes
            css_mode = (doc_attrs[%(#{syntax_hl.name}-css)] || :class).to_sym
            style = doc_attrs[%(#{syntax_hl.name}-style)]
            hl_opts = syntax_hl.highlight? ? { css_mode: css_mode, style: style } : {}
            hl_opts[:nowrap] = nowrap
          end
        end
        # data-id must not be declared on the <div> element (but on the <pre> element for auto-animate)
        attrs = attributes({ id: node.id, class: ['listingblock', node.role, ('fragment' if step?(node))] }.merge(data_attrs(node.attributes.reject do |key, _|
          key == 'data-id'
        end)))
        buf = +''
        buf << %(<div class="title">#{node.captioned_title}</div>) if node.title?
        buf << %(<div class="content">)
        if syntax_hl
          buf << (syntax_hl.format node, lang, hl_opts).to_s
        elsif node.style == 'source'
          code = %(<code#{attributes({ class: [("language-#{lang}" if lang)], 'data-lang' => (lang.to_s if lang) })}>#{node.content || ''}</code>)
          buf << %(<pre#{attributes(class: ['highlight', ('nowrap' if nowrap)])}>#{code}</pre>)
        else
          buf << %(<pre#{attributes({ class: [('nowrap' if nowrap)] })}>#{node.content || ''}</pre>)
        end
        buf << %(</div>)
        %(<div#{attrs}>#{buf}</div>)
      end

      def convert_literal(node, _opts = {})
        attrs = attributes({ id: node.id, class: ['literalblock', node.role, ('fragment' if step?(node))] }.merge(data_attrs(node.attributes)))
        buf = +''
        buf << %(<div class="title">#{node.title}</div>) if node.title?
        buf << %(<div class="content">)
        buf << %(<pre#{attributes({ class: (!(node.document.attr? :prewrap) || (node.option? 'nowrap') ? 'nowrap' : nil) })}>#{node.content}</pre>)
        buf << %(</div>)
        %(<div#{attrs}>#{buf}</div>)
      end

      def convert_notes(node, _opts = {})
        %(<aside class="notes">#{resolve_content(node)}</aside>)
      end

      def convert_olist(node, _opts = {})
        attrs = attributes({ id: node.id, class: ['olist', node.style, node.role] }.merge(data_attrs(node.attributes)))
        buf = +''
        buf << %(<div class="title">#{node.title}</div>) if node.title?
        inner = +''
        node.items.each do |item|
          li = +%(<p>#{item.text}</p>)
          li << item.content.to_s if item.blocks?
          inner << %(<li#{attributes(class: ('fragment' if step_or_role?(node)))}>#{li}</li>)
        end
        buf << %(<ol#{attributes(class: node.style, start: (node.attr :start), type: node.list_marker_keyword)}>#{inner}</ol>)
        %(<div#{attrs}>#{buf}</div>)
      end

      def convert_open(node, _opts = {})
        if node.style == 'abstract'
          if node.parent == node.document && node.document.doctype == 'book'
            puts 'asciidoctor: WARNING: abstract block cannot be used in a document without a title when doctype is book. Excluding block content.'
            ''
          else
            attrs = attributes({ id: node.id, class: ['quoteblock', 'abstract', node.role, ('fragment' if step?(node))] }.merge(data_attrs(node.attributes)))
            buf = +''
            buf << %(<div class="title">#{node.title}</div>) if node.title?
            buf << %(<blockquote>#{node.content}</blockquote>)
            %(<div#{attrs}>#{buf}</div>)
          end
        elsif node.style == 'partintro' && (node.level != 0 || node.parent.context != :section || node.document.doctype != 'book')
          puts 'asciidoctor: ERROR: partintro block can only be used when doctype is book and it\'s a child of a book part. Excluding block content.'
          ''
        elsif (node.has_role? 'aside') || (node.has_role? 'speaker') || (node.has_role? 'notes')
          %(<aside class="notes">#{resolve_content(node)}</aside>)
        else
          attrs = attributes({ id: node.id,
                               class: ['openblock', (node.style == 'open' ? nil : node.style), node.role, ('fragment' if step?(node))] }.merge(data_attrs(node.attributes)))
          buf = +''
          buf << %(<div class="title">#{node.title}</div>) if node.title?
          buf << %(<div class="content">#{node.content}</div>)
          %(<div#{attrs}>#{buf}</div>)
        end
      end

      def convert_outline(node, opts = {})
        return '' if node.sections.empty?

        toclevels = (opts[:toclevels] if opts) || (node.document.attr 'toclevels', DEFAULT_TOCLEVELS).to_i
        slevel = section_level node.sections.first
        buf = +%(<ol class="sectlevel#{slevel}">)
        node.sections.each do |sec|
          buf << %(<li><a href="##{sec.id}">#{section_title sec}</a>)
          if (sec.level < toclevels) && (child_toc = convert(sec, 'outline'))
            buf << child_toc.to_s
          end
          buf << '</li>'
        end
        buf << '</ol>'
        buf
      end

      def convert_page_break(_node, _opts = {})
        %(<div style="page-break-after: always;"></div>)
      end

      def convert_paragraph(node, _opts = {})
        attrs = attributes({ id: node.id, class: ['paragraph', node.role, ('fragment' if step?(node))] }.merge(data_attrs(node.attributes)))
        buf = +''
        buf << %(<div class="title">#{node.title}</div>) if node.title?
        buf << (node.has_role?('small') ? %(<small>#{node.content}</small>) : %(<p>#{node.content}</p>))
        %(<div#{attrs}>#{buf}</div>)
      end

      def convert_pass(node, _opts = {})
        node.content.to_s
      end

      def convert_preamble(_node, _opts = {})
        # preamble is shown on the title slide which is rendered by the document method
        ''
      end

      def convert_quote(node, _opts = {})
        attrs = attributes({ id: node.id, class: ['quoteblock', node.role, ('fragment' if step?(node))] }.merge(data_attrs(node.attributes)))
        buf = +''
        buf << %(<div class="title">#{node.title}</div>) if node.title?
        buf << %(<blockquote>#{node.content}</blockquote>)
        attribution = node.attr?(:attribution) ? (node.attr :attribution) : nil
        citetitle = node.attr?(:citetitle) ? (node.attr :citetitle) : nil
        if attribution || citetitle
          buf << %(<div class="attribution">)
          buf << %(<cite>#{citetitle}</cite>) if citetitle
          if attribution
            buf << '<br>' if citetitle
            buf << %(&#8212; #{attribution})
          end
          buf << %(</div>)
        end
        %(<div#{attrs}>#{buf}</div>)
      end

      def convert_ruler(_node, _opts = {})
        '<hr>'
      end

      def convert_section(node, _opts = {})
        # OPTIONS PROCESSING
        # hide slides on %conceal, %notitle and named "!"
        titleless = (title = node.title) == '!'
        hide_title = titleless || (node.option? :notitle) || (node.option? :conceal)

        vertical_slides = node.find_by(context: :section) { |section| section.level == 2 }

        # extracting block image attributes to find an image to use as a background_image attribute
        data_background_image = data_background_size = data_background_repeat = data_background_position = data_background_transition = nil
        data_background_video = data_background_color = nil

        # process the first image block in the current section that acts as a background
        section_images = node.blocks.map do |block|
          if (ctx = block.context) == :image
            %w[background canvas].include?(block.attributes[1]) ? block : []
          elsif ctx == :section
            []
          else
            block.find_by(context: :image) { |image| %w[background canvas].include?(image.attributes[1]) } || []
          end
        end
        if (bg_image = section_images.flatten.first)
          data_background_image = node.image_uri(bg_image.attr('target'))
          # make sure no crash on nil and default values make sense
          data_background_size = bg_image.attr 'size'
          data_background_repeat = bg_image.attr 'repeat'
          data_background_transition = bg_image.attr 'transition'
          data_background_position = bg_image.attr 'position'
        end

        # background-image section attribute overrides the image one
        data_background_image = node.image_uri(node.attr('background-image')) if node.attr? 'background-image'
        data_background_video = node.media_uri(node.attr('background-video')) if node.attr? 'background-video'
        data_background_color = node.attr 'background-color' if node.attr? 'background-color'

        parent_section_with_vertical_slides = node.level == 1 && !vertical_slides.empty?

        footnotes = lambda do
          slide_fn = Footnotes.slide_footnotes(node)
          if node.document.footnotes? && !(node.parent.attr? 'nofootnotes') && !slide_fn.empty?
            %(<div class="footnotes">#{slide_fn.map { |footnote| %(<div class="footnote">#{footnote.index}. #{footnote.text}</div>) }.join}</div>)
          else
            ''
          end
        end

        section = lambda do
          attrs = attributes({
                               :id => (titleless ? nil : node.id),
                               :class => node.roles,
                               'data-background-gradient' => (node.attr 'background-gradient'),
                               'data-transition' => (node.attr 'transition'),
                               'data-transition-speed' => (node.attr 'transition-speed'),
                               'data-background-color' => data_background_color,
                               'data-background-image' => data_background_image,
                               'data-background-size' => data_background_size || node.attr('background-size'),
                               'data-background-repeat' => data_background_repeat || node.attr('background-repeat'),
                               'data-background-transition' => data_background_transition || node.attr('background-transition'),
                               'data-background-position' => data_background_position || node.attr('background-position'),
                               'data-background-iframe' => (node.attr 'background-iframe'),
                               'data-background-video' => data_background_video,
                               'data-background-video-loop' => (node.attr? 'background-video-loop') || (node.option? 'loop'),
                               'data-background-video-muted' => (node.attr? 'background-video-muted') || (node.option? 'muted'),
                               'data-background-opacity' => (node.attr 'background-opacity'),
                               'data-autoslide' => (node.attr 'autoslide'),
                               'data-state' => (node.attr 'state'),
                               'data-auto-animate' => (node.attr? 'auto-animate') || (node.option? 'auto-animate'),
                               'data-auto-animate-easing' => (node.attr 'auto-animate-easing') || (node.option? 'auto-animate-easing'),
                               'data-auto-animate-unmatched' => (node.attr 'auto-animate-unmatched') || (node.option? 'auto-animate-unmatched'),
                               'data-auto-animate-duration' => (node.attr 'auto-animate-duration') || (node.option? 'auto-animate-duration'),
                               'data-auto-animate-id' => (node.attr 'auto-animate-id'),
                               'data-auto-animate-restart' => (node.attr? 'auto-animate-restart') || (node.option? 'auto-animate-restart')
                             })
          inner = +''
          inner << %(<h2>#{section_title node}</h2>) unless hide_title
          if parent_section_with_vertical_slides
            unless (blocks = node.blocks - vertical_slides).empty?
              inner << %(<div class="slide-content">#{blocks.map(&:convert).join}</div>)
            end
          else
            unless (content = node.content.chomp).empty?
              inner << %(<div class="slide-content">#{content}</div>)
            end
          end
          inner << footnotes.call
          buf = %(<section#{attrs}>#{inner}</section>)
          Footnotes.clear_slide_footnotes
          buf
        end

        # RENDERING
        if parent_section_with_vertical_slides
          # render parent section of vertical slides set
          %(<section>#{section.call}#{vertical_slides.map(&:convert).join}</section>)
        elsif node.level >= 3
          # dynamic tags which maps <hX> with level
          %(<h#{node.level}>#{title}</h#{node.level}>#{node.content.chomp})
        else
          # render standalone slides (or vertical slide subsection)
          section.call
        end
      end

      def convert_sidebar(node, _opts = {})
        if (node.has_role? 'aside') || (node.has_role? 'speaker') || (node.has_role? 'notes')
          %(<aside class="notes">#{resolve_content(node)}</aside>)
        else
          attrs = attributes({ id: node.id, class: ['sidebarblock', node.role, ('fragment' if step_or_role?(node))] }.merge(data_attrs(node.attributes)))
          buf = +%(<div class="content">)
          buf << %(<div class="title">#{node.title}</div>) if node.title?
          buf << node.content.to_s
          buf << %(</div>)
          %(<div#{attrs}>#{buf}</div>)
        end
      end

      def convert_stem(node, _opts = {})
        open, close = Asciidoctor::BLOCK_MATH_DELIMITERS[node.style.to_sym]
        equation = node.content.strip
        equation = node.sub_specialcharacters equation if (node.subs.nil? || node.subs.empty?) && !(node.attr? 'subs')
        equation = %(#{open}#{equation}#{close}) unless (equation.start_with? open) && (equation.end_with? close)
        attrs = attributes({ id: node.id, class: ['stemblock', node.role, ('fragment' if step_or_role?(node))] }.merge(data_attrs(node.attributes)))
        buf = +''
        buf << %(<div class="title">#{node.title}</div>) if node.title?
        buf << %(<div class="content">#{equation}</div>)
        %(<div#{attrs}>#{buf}</div>)
      end

      def convert_table(node, _opts = {})
        classes = ['tableblock', "frame-#{node.attr :frame, 'all'}", "grid-#{node.attr :grid, 'all'}", node.role, ('fragment' if step?(node))]
        styles = [("width:#{node.attr :tablepcwidth}%" unless node.option? 'autowidth'), ("float:#{node.attr :float}" if node.attr? :float)].compact.join('; ')
        attrs = attributes({ id: node.id, class: classes, style: styles }.merge(data_attrs(node.attributes)))
        buf = +''
        buf << %(<caption class="title">#{node.captioned_title}</caption>) if node.title?
        unless (node.attr :rowcount).zero?
          buf << '<colgroup>'
          if node.option? 'autowidth'
            node.columns.each { buf << '<col>' }
          else
            node.columns.each { |col| buf << %(<col style="width:#{col.attr :colpcwidth}%">) }
          end
          buf << '</colgroup>'
          %i[head foot body].reject { |tblsec| node.rows[tblsec].empty? }.each do |tblsec|
            buf << %(<t#{tblsec}>)
            node.rows[tblsec].each do |row|
              buf << '<tr>'
              row.each do |cell|
                # store reference of content in advance to resolve attribute assignments in cells
                cell_content = if tblsec == :head
                                 cell.text
                               else
                                 case cell.style
                                 when :literal
                                   cell.text
                                 else
                                   cell.content
                                 end
                               end
                cell_attrs = attributes(
                  class: ['tableblock', "halign-#{cell.attr :halign}", "valign-#{cell.attr :valign}"],
                  colspan: cell.colspan, rowspan: cell.rowspan,
                  style: (node.document.attr?(:cellbgcolor) ? %(background-color:#{node.document.attr :cellbgcolor};) : nil)
                )
                cell_inner = if tblsec == :head
                               cell_content.to_s
                             else
                               case cell.style
                               when :asciidoc
                                 %(<div>#{cell_content}</div>)
                               when :literal
                                 %(<div class="literal"><pre>#{cell_content}</pre></div>)
                               when :header
                                 cell_content.map { |text| %(<p class="tableblock header">#{text}</p>) }.join
                               else
                                 cell_content.map { |text| %(<p class="tableblock">#{text}</p>) }.join
                               end
                             end
                tag = tblsec == :head || cell.style == :header ? 'th' : 'td'
                buf << %(<#{tag}#{cell_attrs}>#{cell_inner}</#{tag}>)
              end
              buf << '</tr>'
            end
          end
        end
        %(<table#{attrs}>#{buf}</table>)
      end

      def convert_thematic_break(_node, _opts = {})
        '<hr>'
      end

      def convert_title_slide(node, _opts = {})
        bg_image = node.attr?('title-slide-background-image') ? node.image_uri(node.attr('title-slide-background-image')) : nil
        bg_video = node.attr?('title-slide-background-video') ? node.media_uri(node.attr('title-slide-background-video')) : nil
        attrs = attributes({
                             :class => ['title', node.role],
                             'data-state' => 'title',
                             'data-transition' => (node.attr 'title-slide-transition'),
                             'data-transition-speed' => (node.attr 'title-slide-transition-speed'),
                             'data-background' => (node.attr 'title-slide-background'),
                             'data-background-size' => (node.attr 'title-slide-background-size'),
                             'data-background-image' => bg_image,
                             'data-background-video' => bg_video,
                             'data-background-video-loop' => (node.attr 'title-slide-background-video-loop'),
                             'data-background-video-muted' => (node.attr 'title-slide-background-video-muted'),
                             'data-background-opacity' => (node.attr 'title-slide-background-opacity'),
                             'data-background-iframe' => (node.attr 'title-slide-background-iframe'),
                             'data-background-color' => (node.attr 'title-slide-background-color'),
                             'data-background-repeat' => (node.attr 'title-slide-background-repeat'),
                             'data-background-position' => (node.attr 'title-slide-background-position'),
                             'data-background-transition' => (node.attr 'title-slide-background-transition')
                           })
        buf = +''
        buf << if (title_obj = node.doctitle partition: true, use_fallback: true).subtitle?
                 %(<h1>#{slice_text node, title_obj.title, (header_slice = node.header.option? :slice)}</h1><h2>#{slice_text node, title_obj.subtitle, header_slice}</h2>)
               else
                 %(<h1>#{node.header.title}</h1>)
               end
        preamble = node.document.find_by context: :preamble
        buf << %(<div class="preamble">#{preamble.pop.content}</div>) unless preamble.nil? || preamble.empty?
        buf << generate_authors(node.document).to_s
        %(<section#{attrs}>#{buf}</section>)
      end

      def convert_toc(node, _opts = {})
        content = %(<div id="toctitle">#{node.document.attr 'toc-title'}</div>) +
                  convert(node.document, 'outline').to_s
        %(<div#{attributes(id: 'toc', class: (node.document.attr 'toc-class', 'toc'))}>#{content}</div>)
      end

      def convert_ulist(node, _opts = {})
        if (checklist = node.option?(:checklist) ? 'checklist' : nil)
          if node.option? :interactive
            marker_checked = '<input type="checkbox" data-item-complete="1" checked>'
            marker_unchecked = '<input type="checkbox" data-item-complete="0">'
          elsif node.document.attr? :icons, 'font'
            marker_checked = '<i class="icon-check"></i>'
            marker_unchecked = '<i class="icon-check-empty"></i>'
          else
            # could use &#9745 (checked ballot) and &#9744 (ballot) w/o font instead
            marker_checked = '<input type="checkbox" data-item-complete="1" checked disabled>'
            marker_unchecked = '<input type="checkbox" data-item-complete="0" disabled>'
          end
        end
        attrs = attributes({ id: node.id, class: ['ulist', checklist, node.style, node.role] }.merge(data_attrs(node.attributes)))
        buf = +''
        buf << %(<div class="title">#{node.title}</div>) if node.title?
        inner = +''
        node.items.each do |item|
          li = +'<p>'
          li << if checklist && (item.attr? :checkbox)
                  %(#{item.attr?(:checked) ? marker_checked : marker_unchecked}#{item.text})
                else
                  item.text.to_s
                end
          li << '</p>'
          li << item.content.to_s if item.blocks?
          inner << %(<li#{attributes(class: ('fragment' if step_or_role?(node)))}>#{li}</li>)
        end
        buf << %(<ul#{attributes(class: checklist || node.style)}>#{inner}</ul>)
        %(<div#{attrs}>#{buf}</div>)
      end

      def convert_verse(node, _opts = {})
        attrs = attributes({ id: node.id, class: ['verseblock', node.role, ('fragment' if step?(node))] }.merge(data_attrs(node.attributes)))
        buf = +''
        buf << %(<div class="title">#{node.title}</div>) if node.title?
        buf << %(<pre class="content">#{node.content}</pre>)
        attribution = node.attr?(:attribution) ? (node.attr :attribution) : nil
        citetitle = node.attr?(:citetitle) ? (node.attr :citetitle) : nil
        if attribution || citetitle
          buf << %(<div class="attribution">)
          buf << %(<cite>#{citetitle}</cite>) if citetitle
          if attribution
            buf << '<br>' if citetitle
            buf << %(&#8212; #{attribution})
          end
          buf << %(</div>)
        end
        %(<div#{attrs}>#{buf}</div>)
      end

      def convert_video(node, _opts = {})
        # in a slide-deck context we assume video should take as much place as possible
        # unless already specified
        no_stretch = (node.attr? :width) || (node.attr? :height)
        width = node.attr?(:width) ? (node.attr :width) : '100%'
        height = node.attr?(:height) ? (node.attr :height) : '100%'
        # we apply revealjs stretch class to the videoblock take all the place we can
        attrs = attributes({ id: node.id,
                             class: ['videoblock', node.style, node.role, (no_stretch ? nil : 'stretch'), ('fragment' if step_or_role?(node))] }.merge(data_attrs(node.attributes)))
        buf = +''
        buf << %(<div class="title">#{node.captioned_title}</div>) if node.title?
        case node.attr :poster
        when 'vimeo'
          unless (asset_uri_scheme = (node.attr :asset_uri_scheme, 'https')).empty?
            asset_uri_scheme = %(#{asset_uri_scheme}:)
          end
          start_anchor = node.attr?(:start) ? "#at=#{node.attr :start}" : nil
          delimiter = ['?']
          loop_param = node.option?('loop') ? %(#{delimiter.pop || '&amp;'}loop=1) : ''
          muted_param = node.option?('muted') ? %(#{delimiter.pop || '&amp;'}muted=1) : ''
          src = %(#{asset_uri_scheme}//player.vimeo.com/video/#{node.attr :target}#{loop_param}#{muted_param}#{start_anchor})
          # We need to delegate autoplay into the iframe starting with Chrome 62 (and other browsers too)
          # See https://developers.google.com/web/updates/2017/09/autoplay-policy-changes#iframe
          buf << %(<iframe#{attributes(width: width, height: height, src: src, frameborder: 0,
                                       webkitAllowFullScreen: true, mozallowfullscreen: true, allowFullScreen: true,
                                       'data-autoplay' => (node.option? 'autoplay'),
                                       allow: (node.option?('autoplay') ? 'autoplay' : nil))}></iframe>)
        when 'youtube'
          unless (asset_uri_scheme = (node.attr :asset_uri_scheme, 'https')).empty?
            asset_uri_scheme = %(#{asset_uri_scheme}:)
          end
          params = ['rel=0']
          params << "start=#{node.attr :start}" if node.attr? :start
          params << "end=#{node.attr :end}" if node.attr? :end
          params << 'loop=1' if node.option? 'loop'
          params << 'mute=1' if node.option? 'muted'
          params << 'controls=0' if node.option? 'nocontrols'
          src = %(#{asset_uri_scheme}//www.youtube.com/embed/#{node.attr :target}?#{params * '&amp;'})
          # We need to delegate autoplay into the iframe starting with Chrome 62 (and other browsers too)
          # See https://developers.google.com/web/updates/2017/09/autoplay-policy-changes#iframe
          buf << %(<iframe#{attributes(width: width, height: height, src: src,
                                       frameborder: 0, allowfullscreen: !(node.option? 'nofullscreen'),
                                       'data-autoplay' => (node.option? 'autoplay'),
                                       allow: (node.option?('autoplay') ? 'autoplay' : nil))}></iframe>)
        else
          buf << %(<video#{attributes({ src: node.media_uri(node.attr(:target)), width: width, height: height,
                                        poster: (node.attr(:poster) ? node.media_uri(node.attr(:poster)) : nil),
                                        'data-autoplay' => (node.option? 'autoplay'), controls: !(node.option? 'nocontrols'),
                                        loop: (node.option? 'loop') })}>Your browser does not support the video tag.</video>)
        end
        %(<div#{attrs}>#{buf}</div>)
      end

      def convert_document(node, _opts = {})
        slides_content = node.content
        slides = lambda do
          buf = +''
          unless node.noheader
            unless (header_docinfo = node.docinfo :header, '-revealjs.html').empty?
              buf << header_docinfo.to_s
            end
            buf << convert(node, 'title_slide') if node.header?
          end
          buf << slides_content.to_s
          unless (footer_docinfo = node.docinfo :footer, '-revealjs.html').empty?
            buf << footer_docinfo.to_s
          end
          buf
        end

        revealjsdir = (node.attr :revealjsdir, 'reveal.js')
        unless (asset_uri_scheme = (node.attr 'asset-uri-scheme', 'https')).empty?
          asset_uri_scheme = %(#{asset_uri_scheme}:)
        end
        cdn_base = %(#{asset_uri_scheme}//cdnjs.cloudflare.com/ajax/libs)

        buf = +'<!DOCTYPE html><html'
        lang = (node.attr :lang, 'en' unless node.attr? :nolang)
        buf << %( lang="#{lang}") if lang
        buf << '><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, minimal-ui">'
        buf << %(<title>#{node.doctitle sanitize: true, use_fallback: true}</title>)

        %i[description keywords author copyright].each do |key|
          buf << %(<meta#{attributes(name: key.to_s, content: (node.attr key))}>) if node.attr? key
        end
        if node.attr? 'favicon'
          if (icon_href = node.attr 'favicon').empty?
            icon_href = 'favicon.ico'
            icon_type = 'image/x-icon'
          elsif (icon_ext = File.extname icon_href)
            icon_type = icon_ext == '.ico' ? 'image/x-icon' : %(image/#{icon_ext.slice 1, icon_ext.length})
          else
            icon_type = 'image/x-icon'
          end
          buf << %(<link rel="icon" type="#{icon_type}" href="#{icon_href}">)
        end
        linkcss = (node.attr? 'linkcss')
        buf << %(<link rel="stylesheet" href="#{revealjsdir}/dist/reset.css"><link rel="stylesheet" href="#{revealjsdir}/dist/reveal.css">)
        # Default theme required even when using custom theme
        buf << %(<link#{attributes(rel: 'stylesheet',
                                   href: (node.attr :revealjs_customtheme, %(#{revealjsdir}/dist/theme/#{node.attr 'revealjs_theme', 'black'}.css)), id: 'theme')}>)
        buf << %(<!--This CSS is generated by the Asciidoctor reveal.js converter to further integrate AsciiDoc's existing semantic with reveal.js-->)
        buf << %(<style type="text/css">#{Asciidoctor::Revealjs::Stylesheet::COMPATIBILITY}</style>)
        if node.attr? :icons, 'font'
          # iconfont-remote is implicitly set by Asciidoctor core. See https://github.com/asciidoctor/asciidoctor.org/issues/361
          if node.attr? 'iconfont-remote'
            if (iconfont_cdn = (node.attr 'iconfont-cdn'))
              buf << %(<link#{attributes(rel: 'stylesheet', href: iconfont_cdn)}>)
            else
              # default icon font is Font Awesome
              font_awesome_version = (node.attr 'font-awesome-version', '5.15.1')
              buf << %(<link#{attributes(rel: 'stylesheet', href: %(#{cdn_base}/font-awesome/#{font_awesome_version}/css/all.min.css))}>)
              buf << %(<link#{attributes(rel: 'stylesheet', href: %(#{cdn_base}/font-awesome/#{font_awesome_version}/css/v4-shims.min.css))}>)
            end
          else
            buf << %(<link#{attributes(rel: 'stylesheet',
                                       href: (node.normalize_web_path %(#{node.attr 'iconfont-name', 'font-awesome'}.css),
                                                                      (node.attr 'stylesdir', ''), false))}>)
          end
        end
        buf << generate_stem(node, cdn_base).to_s
        syntax_hl = node.syntax_highlighter
        buf << (syntax_hl.docinfo :head, node, cdn_base_url: cdn_base, linkcss: linkcss, self_closing_tag_slash: '/').to_s if syntax_hl&.docinfo? :head
        if node.attr? :customcss
          buf << %(<link#{attributes(rel: 'stylesheet', href: ((customcss = node.attr :customcss).empty? ? 'asciidoctor-revealjs.css' : customcss))}>)
        end
        unless (docinfo_head = node.docinfo :head, '-revealjs.html').empty?
          buf << docinfo_head.to_s
        end
        buf << %(</head><body><div class="reveal"><div class="slides">)
        # Any section element inside of this container is displayed as a slide
        buf << slides.call
        buf << %(</div></div>)
        buf << Asciidoctor::Revealjs::RevealJsOptions.script(node, revealjsdir)

        buf << (syntax_hl.docinfo :footer, node, cdn_base_url: cdn_base, linkcss: linkcss, self_closing_tag_slash: '/').to_s if syntax_hl&.docinfo? :footer
        unless (docinfo_content = (node.docinfo :footer, '.html')).empty?
          buf << docinfo_content.to_s
        end
        buf << '</body></html>'
        buf
      end

      # Retrieves the built-in html5 converter associated with this node.
      #
      # Returns the instance of the Asciidoctor::Converter::Html5Converter.
      def html5_converter(node)
        node.converter.instance_variable_get('@delegate_converter')
      end

      # Builds the inner markup of an inline image (without its surrounding span).
      def inline_image_content(node)
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
            attrs = node.attr?('title') ? %( title="#{node.attr 'title'}") : ''
            img = %(<i class="#{i_class_attr_val}"#{attrs}></i>)
          elsif icons
            attrs = node.attr?('width') ? %( width="#{node.attr 'width'}") : ''
            attrs = %(#{attrs} height="#{node.attr 'height'}") if node.attr? 'height'
            attrs = %(#{attrs} title="#{node.attr 'title'}") if node.attr? 'title'
            img = %(<img src="#{src = node.icon_uri target}" alt="#{encode_attribute_value node.alt}"#{attrs}>)
          else
            img = %([#{node.alt}&#93;)
          end
        else
          html_attrs = node.attr?('width') ? %( width="#{node.attr 'width'}") : ''
          html_attrs = %(#{html_attrs} height="#{node.attr 'height'}") if node.attr? 'height'
          html_attrs = %(#{html_attrs} title="#{node.attr 'title'}") if node.attr? 'title'
          img, src = img_tag(node, target, html_attrs)
        end
        img_link(node, src, img)
      end

      # Builds the inner markup of a block image (without its surrounding div).
      def image_content(node)
        # When the stretch class is present, block images will take the most space
        # they can take. Setting width and height can override that.
        # We pinned the 100% to height to avoid aspect ratio breakage and since
        # widescreen monitors are the most popular, chances are that height will
        # be the biggest constraint
        height_value = if node.has_role?('stretch') && !(node.attr?(:width) || node.attr?(:height))
                         '100%'
                       elsif node.attr? 'height'
                         node.attr 'height'
                       end
        html_attrs = node.attr?('width') ? %( width="#{node.attr 'width'}") : ''
        html_attrs = %(#{html_attrs} height="#{height_value}") if height_value
        html_attrs = %(#{html_attrs} title="#{node.attr 'title'}") if node.attr? 'title'
        html_attrs = %(#{html_attrs} style="background: #{node.attr :background}") if node.attr? 'background'
        img, src = img_tag(node, node.attr('target'), html_attrs)
        img_link(node, src, img)
      end

      def img_tag(node, target, html_attrs)
        if ((node.attr? 'format', 'svg') || (target.include? '.svg')) && node.document.safe < ::Asciidoctor::SafeMode::SECURE
          if node.option? 'inline'
            img = (html5_converter(node).read_svg_contents node, target) || %(<span class="alt">#{node.alt}</span>)
          elsif node.option? 'interactive'
            fallback = node.attr?('fallback') ? %(<img src="#{node.image_uri node.attr 'fallback'}" alt="#{encode_attribute_value node.alt}"#{html_attrs}>) : %(<span class="alt">#{node.alt}</span>)
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
      def img_link(node, src, content)
        if (node.attr? 'link') && ((href_attr_val = node.attr 'link') != 'self' || (href_attr_val = src))
          if (link_preview_value = bool_data_attr(node, :link_preview))
            data_preview_attr = %( data-preview-link="#{link_preview_value unless link_preview_value == true}")
          end
          return %(<a class="image" href="#{href_attr_val}"#{(append_link_constraint_attrs node).join}#{data_preview_attr}>#{content}</a>)
        end

        content
      end

      # Between delimiters (--) is code taken from asciidoctor-bespoke 1.0.0.alpha.1
      # Licensed under MIT, Copyright (C) 2015-2016 Dan Allen and the Asciidoctor Project
      #--
      # Retrieve the converted content, wrap it in a `<p>` element if
      # the content_model equals :simple and return the result.
      #
      # Returns the block content as a String, wrapped inside a `<p>` element if
      # the content_model equals `:simple`.
      def resolve_content(node)
        node.content_model == :simple ? %(<p>#{node.content}</p>) : node.content
      end

      # Copied from asciidoctor/lib/asciidoctor/converter/html5.rb (method is private)
      def append_link_constraint_attrs(node, attrs = [])
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
      def encode_attribute_value(val)
        val.include?('"') ? (val.gsub '"', '&quot;') : val
      end

      # Copied from asciidoctor/lib/asciidoctor/converter/semantic-html5.rb which is not yet shipped
      # @todo remove this code when the new converter becomes available in the main gem
      def generate_authors(node)
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
      def format_author(node, author)
        %(<span class="author">#{node.sub_replacements author.name}#{%( #{node.sub_macros author.email}) if author.email}</span>)
      end

      # Generate the Mathjax markup to process STEM expressions
      # @param node [Asciidoctor::Document]
      # @param cdn_base [String]
      # @return [String]
      def generate_stem(node, cdn_base)
        return unless node.attr?(:stem)

        eqnums_val = node.attr('eqnums', STEM_EQNUMS_NONE).downcase
        eqnums_val = STEM_EQNUMS_AMS unless STEM_EQNUMS_VALID_VALUES.include?(eqnums_val)
        mathjax_configuration = {
          tex: {
            inlineMath: [Asciidoctor::INLINE_MATH_DELIMITERS[:latexmath]],
            displayMath: [Asciidoctor::BLOCK_MATH_DELIMITERS[:latexmath]],
            processEscapes: false,
            tags: eqnums_val
          },
          options: {
            ignoreHtmlClass: 'nostem|nolatexmath'
          },
          asciimath: {
            delimiters: [Asciidoctor::BLOCK_MATH_DELIMITERS[:asciimath]]
          },
          loader: {
            load: ['input/asciimath', 'output/chtml', 'ui/menu']
          }
        }
        mathjaxdir = node.attr('mathjaxdir', "#{cdn_base}/mathjax/#{MATHJAX_VERSION}/es5")
        %(<script>window.MathJax = #{JSON.generate(mathjax_configuration)};</script>) +
          %(<script async src="#{mathjaxdir}/tex-mml-chtml.js"></script>)
      end

      # If the AsciiDoc attribute doesn't exist, no HTML attribute is added
      # If the AsciiDoc attribute exist and is a true value, HTML attribute is enabled (bool)
      # If the AsciiDoc attribute exist and is a false value, HTML attribute is a false string
      # Ex: a feature is enabled globally but can be disabled using a data- attribute on individual items
      # :revealjs_previewlinks: True
      # then link::example.com[Link text, preview=false]
      # Here the template must have data-preview-link="false" not just no data-preview-link attribute
      def bool_data_attr(node, val)
        return false unless node.attr?(val)

        if node.attr(val).downcase == 'false' || node.attr(val) == '0'
          'false'
        else
          true
        end
      end

      # Whether the node should carry the reveal.js +fragment+ class because it is
      # part of a step. Variant used by most block elements.
      def step?(node)
        (node.option? :step) || (node.attr? 'step')
      end

      # Same as #step? but also honours the +step+ role. Used by the list-like
      # elements (colist, olist, ulist, sidebar, stem, video).
      def step_or_role?(node)
        (node.option? :step) || (node.has_role? 'step') || (node.attr? 'step')
      end

      ##
      # Serializes a Hash of attributes into the string that goes inside an opening
      # tag, e.g. { id: 'x', class: ['a', nil, 'b'] } => %( id="x" class="a b").
      #
      # The HTML tag itself is written literally at the call site; only this
      # (genuinely data-driven) part is factored out. The rules are:
      # - +nil+, +false+ and empty values are omitted (so an absent id produces
      #   nothing rather than id="");
      # - +true+ produces a boolean attribute (just the name, e.g. controls);
      # - Array values are compacted and joined with a space (and omitted if the
      #   array collapses to nothing), just like Slim does for class lists.
      #
      # @param pairs [Hash]
      # @return [String] the attributes string with a leading space, or '' if none.
      #
      def attributes(pairs)
        pairs.inject(+'') do |str, (k, v)|
          v = v.compact.join(' ') if v.is_a? Array
          next str unless v && (v == true || !v.nil_or_empty?)

          str << (v == true ? %( #{k}) : %( #{k}="#{v}"))
        end
      end

      #
      # Extracts data- attributes from the attributes.
      # @param attributes [Hash] (default: {})
      # @return [Hash] a Hash that contains only data- attributes
      #
      def data_attrs(attributes)
        # key can be an Integer (for positional attributes)
        attributes.to_h { |key, value| key == 'step' ? ['data-fragment-index', value] : [key, value] }
                  .select { |key, _| key.to_s.start_with?('data-') }
      end

      #
      # Wrap an inline text in a <span> element if the node contains a role, an id or data- attributes.
      # @param node [Asciidoctor::AbstractNode] the node being converted.
      # @param content [#to_s] the content; +nil+ to call the block. (default: nil).
      # @return [String] the content or the content wrapped in a <span> element as string
      #
      def inline_text_container(node, content = nil)
        data_attrs = data_attrs(node.attributes)
        classes = [node.role, ('fragment' if (node.option? :step) || (node.attr? 'step') || (node.roles.include? 'step'))].compact
        if !node.roles.empty? || !data_attrs.empty? || !node.id.nil?
          %(<span#{attributes({ id: node.id, class: classes }.merge(data_attrs))}>#{content || (yield if block_given?)}</span>)
        else
          content || (yield if block_given?)
        end
      end

      ##
      # Returns corrected section level.
      #
      # @param sec [Asciidoctor::Section] the section node.
      # @return [Integer]
      #
      def section_level(sec)
        sec.level.zero? && sec.special ? 1 : sec.level
      end

      ##
      # Returns the captioned section's title, optionally numbered.
      #
      # @param sec [Asciidoctor::Section] the section node.
      # @return [String]
      #
      def section_title(sec)
        sectnumlevels = sec.document.attr(:sectnumlevels, DEFAULT_SECTNUMLEVELS).to_i

        if sec.numbered && !sec.caption && sec.level <= sectnumlevels
          [sec.sectnum, sec.captioned_title].join(' ')
        else
          sec.captioned_title
        end
      end

      def slice_text(node, str, active = nil)
        if (active || (active.nil? && (node.option? :slice))) && (str.include? '  ')
          (str.split SLICE_HINT_RX).map { |line| %(<span class="line">#{line}</span>) }.join '\n'
        else
          str
        end
      end
    end
  end
end
