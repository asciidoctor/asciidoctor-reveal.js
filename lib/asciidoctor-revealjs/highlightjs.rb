# frozen_string_literal: true
module Asciidoctor
  module Revealjs
    module SyntaxHighlighter
      # Override the built-in highlight.js syntax highlighter
      class HighlightJsAdapter < Asciidoctor::SyntaxHighlighter::Base
        register_for 'highlightjs', 'highlight.js'

        def initialize *args
          super
          @name = @pre_class = 'highlightjs'
        end

        # Convert between highlight notation formats
        # In addition to Asciidoctor's linenum converter leveraging core's resolve_lines_to_highlight,
        # we also support reveal.js step-by-step highlights.
        # The steps are split using the | character
        # For example, this method makes "1..3|6,7" into "1,2,3|6,7"
        def _convert_highlight_to_revealjs node
          return node.attributes["highlight"].split("|").collect { |linenums|
            node.resolve_lines_to_highlight(node.content, linenums).join(",")
          }.join("|")
        end

        def format node, lang, opts
          super node, lang, (opts.merge transform: proc { |_, code|
            code['class'] = %(language-#{lang || 'none'} hljs)
            code['data-noescape'] = true

            if node.attributes.key?("highlight")
              code['data-line-numbers'] = self._convert_highlight_to_revealjs(node)
            elsif node.attributes.key?("linenums")
              code['data-line-numbers'] = ''
            end
          })
        end

        def docinfo? location
          location == :footer
        end

        def docinfo location, doc, opts
          if RUBY_ENGINE == 'opal' && JAVASCRIPT_PLATFORM == 'node'
            revealjsdir = (doc.attr :revealjsdir, 'node_modules/reveal.js')
          else
            revealjsdir = (doc.attr :revealjsdir, 'reveal.js')
          end
          if doc.attr? 'highlightjs-theme'
            theme_href = doc.attr 'highlightjs-theme'
          else
            theme_href = "#{revealjsdir}/lib/css/monokai.css"
          end
          %(<link rel="stylesheet" href="#{theme_href}"#{opts[:self_closing_tag_slash]}>)
        end
      end
    end
  end
end
