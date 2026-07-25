# frozen_string_literal: true

module Asciidoctor
  module Revealjs
    module SyntaxHighlighter
      # Override the built-in highlight.js syntax highlighter
      class HighlightJsAdapter < Asciidoctor::SyntaxHighlighter::Base
        register_for 'highlightjs', 'highlight.js'

        # REMIND: we cannot use Highlight.js 11+ because unescaped HTML support has been removed:
        # https://github.com/highlightjs/highlight.js/issues/2889
        # We are using unescaped HTML in source blocks for callout.
        HIGHLIGHT_JS_VERSION = '10.7.3'

        # Registering under the 'highlightjs'/'highlight.js' name overrides the built-in
        # highlight.js syntax highlighter for every backend, not just revealjs - the
        # SyntaxHighlighter registry has no notion of "per backend". Delegate to the
        # built-in adapter for any other backend, so this converter's reveal.js-specific
        # markup (data-line-numbers, data-noescape, the reveal.js highlight plugin
        # docinfo) only shows up when actually converting to revealjs. See #489.
        def initialize(name, backend = 'html5', opts = {})
          super
          @name = @pre_class = 'highlightjs'
          @delegate = ::Asciidoctor::SyntaxHighlighter::HighlightJsAdapter.new(name, backend, opts) unless %w[revealjs reveal.js].include?(backend)
        end

        # Convert between highlight notation formats
        # In addition to Asciidoctor's linenum converter leveraging core's resolve_lines_to_highlight,
        # we also support reveal.js step-by-step highlights.
        # The steps are split using the | character
        # For example, this method makes "1..3|6,7" into "1,2,3|6,7"
        def _convert_highlight_to_revealjs(node)
          node.attributes['highlight'].split('|').collect do |linenums|
            node.resolve_lines_to_highlight(node.content, linenums).join(',')
          end.join('|')
        end

        def format(node, lang, opts)
          return @delegate.format(node, lang, opts) if @delegate

          super(node, lang, (opts.merge transform: proc { |pre, code|
            code['class'] = %(language-#{lang || 'none'} hljs)
            code['data-noescape'] = true
            if (id = node.attr('data-id'))
              pre['data-id'] = id
            end
            code['data-trim'] = '' if node.option?('trim')

            if node.attributes.key?('highlight')
              code['data-line-numbers'] = _convert_highlight_to_revealjs(node)
            elsif node.attributes.key?('linenums')
              code['data-line-numbers'] = ''
            end
          }))
        end

        def docinfo?(location)
          return @delegate.docinfo?(location) if @delegate

          location == :footer
        end

        def docinfo(location, doc, opts)
          return @delegate.docinfo(location, doc, opts) if @delegate

          revealjsdir = (doc.attr :revealjsdir, 'reveal.js')
          theme_href = if doc.attr? 'highlightjs-theme'
                         doc.attr 'highlightjs-theme'
                       else
                         "#{revealjsdir}/dist/plugin/highlight/monokai.css"
                       end
          base_url = doc.attr 'highlightjsdir', %(#{opts[:cdn_base_url]}/highlight.js/#{HIGHLIGHT_JS_VERSION})
          %(<link rel="stylesheet" href="#{theme_href}"#{opts[:self_closing_tag_slash]}>
<script src="#{base_url}/highlight.min.js"></script>
#{if doc.attr?('highlightjs-languages')
    ((doc.attr 'highlightjs-languages').split ',').map do |lang|
      %(<script src="#{base_url}/languages/#{lang.lstrip}.min.js"></script>\n)
    end.join
  end}
<script>
hljs.configure({
  ignoreUnescapedHTML: true,
});
#{HIGHLIGHT_PLUGIN_SOURCE}
</script>)
        end

        # this file was copied-pasted from https://raw.githubusercontent.com/hakimel/reveal.js/6.0.1/plugin/highlight/plugin.js
        # (adapted from an ES module into a plain script, since it is inlined into the page)
        # please note that the bundled highlight.js code was removed so we can use the latest version from cdnjs.
        # Shared with the JavaScript implementation; see data/highlight-plugin.js.
        HIGHLIGHT_PLUGIN_SOURCE = File.read(File.join(__dir__, '..', '..', 'data', 'highlight-plugin.js')).freeze
      end
    end
  end
end
