// Port of lib/asciidoctor_revealjs/highlightjs.rb
//
// Overrides the built-in highlight.js syntax highlighter so that source blocks
// are tailored for reveal.js' highlight plugin (client-side highlighting,
// data-noescape, data-line-numbers, monokai theme, plugin docinfo).

import { readFileSync } from 'node:fs'
import { SyntaxHighlighterBase } from '@asciidoctor/core'

// REMIND: we cannot use Highlight.js 11+ because unescaped HTML support has been
// removed (https://github.com/highlightjs/highlight.js/issues/2889). We use
// unescaped HTML in source blocks for callouts.
const HIGHLIGHT_JS_VERSION = '10.7.3'

// reveal.js highlight plugin source (bundled highlight.js code removed so the
// latest version can be loaded from a CDN). Kept verbatim in a data file.
const HIGHLIGHT_PLUGIN_SOURCE = readFileSync(new URL('../data/highlight-plugin.js', import.meta.url), 'utf8')

export default class HighlightJsAdapter extends SyntaxHighlighterBase {
  constructor (name, backend = 'html5', opts = {}) {
    super(name, backend, opts)
    this.name = 'highlightjs'
    this._preClass = 'highlightjs'
  }

  // Convert between highlight notation formats. In addition to Asciidoctor's
  // linenum converter, we support reveal.js step-by-step highlights (split with
  // the | character). For example, "1..3|6,7" becomes "1,2,3|6,7".
  async _convertHighlightToRevealjs (node) {
    const content = await node.content()
    return node.getAttribute('highlight').split('|').map((linenums) => node.resolveLinesToHighlight(content, linenums).join(',')).join('|')
  }

  async format (node, lang, opts) {
    let lineNumbers
    // NOTE: the Ruby parser also exposes a `linenums` attribute for source blocks;
    // Asciidoctor.js only sets the `linenums` option, so check both.
    if (node.hasAttribute('highlight')) lineNumbers = await this._convertHighlightToRevealjs(node)
    else if (node.hasAttribute('linenums') || node.hasOption('linenums')) lineNumbers = ''
    const transform = (pre, code) => {
      code.class = `language-${lang || 'none'} hljs`
      code['data-noescape'] = true
      const id = node.getAttribute('data-id')
      if (id != null) pre['data-id'] = id
      if (node.hasOption('trim')) code['data-trim'] = ''
      if (lineNumbers !== undefined) code['data-line-numbers'] = lineNumbers
    }
    return super.format(node, lang, { ...opts, transform })
  }

  hasDocinfo (location) {
    return location === 'footer'
  }

  docinfo (location, doc, opts) {
    const revealjsdir = doc.getAttribute('revealjsdir', 'node_modules/reveal.js')
    const themeHref = doc.hasAttribute('highlightjs-theme')
      ? doc.getAttribute('highlightjs-theme')
      : `${revealjsdir}/dist/plugin/highlight/monokai.css`
    const baseUrl = doc.getAttribute('highlightjsdir', `${opts.cdn_base_url}/highlight.js/${HIGHLIGHT_JS_VERSION}`)
    const languages = doc.hasAttribute('highlightjs-languages')
      ? doc.getAttribute('highlightjs-languages').split(',').map((lang) => `<script src="${baseUrl}/languages/${lang.replace(/^\s+/, '')}.min.js"></script>\n`).join('')
      : ''
    return `<link rel="stylesheet" href="${themeHref}"${opts.self_closing_tag_slash}>
<script src="${baseUrl}/highlight.min.js"></script>
${languages}
<script>
${HIGHLIGHT_PLUGIN_SOURCE}
hljs.configure({
  ignoreUnescapedHTML: true,
});
hljs.highlightAll();
</script>`
  }
}
