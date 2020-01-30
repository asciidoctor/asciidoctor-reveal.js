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

        # Convert between slide notation formats
        # Asciidoctor uses 1..3,6,8 whereas reveal.js expects 1-3,6,8
        def _convert_linedef_to_revealjs highlight_lines
          return highlight_lines.gsub("..", "-")
        end

        def format node, lang, opts
          super node, lang, (opts.merge transform: proc { |_, code|
            code['class'] = %(language-#{lang || 'none'} hljs)
            code['data-noescape'] = true
            # Note for review: should the API be modified to give easier access to this?
            if node.attributes.key?("highlight")
              code['data-line-numbers'] = self._convert_linedef_to_revealjs(node.attributes["highlight"])
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
