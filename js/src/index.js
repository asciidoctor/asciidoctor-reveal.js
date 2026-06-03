// Public entry point for the native JavaScript reveal.js converter.
//
// Usage:
//   import asciidoctor from '@asciidoctor/core'
//   import { register } from '@asciidoctor/reveal.js-converter'
//   register()
//   const html = await asciidoctor.convert(input, { backend: 'revealjs', standalone: true })

import { readFileSync } from 'node:fs'
import { ConverterFactory, SyntaxHighlighter } from '@asciidoctor/core'
import RevealJsConverter from './converter.js'
import HighlightJsAdapter from './highlightjs.js'

const pkg = JSON.parse(readFileSync(new URL('../../package.json', import.meta.url), 'utf8'))

// Register the reveal.js converter so Asciidoctor.js can use the `revealjs`
// (and `reveal.js`) backends, plus the reveal.js-tailored highlight.js
// syntax highlighter. An optional registry implementing `register` may be
// provided; otherwise the global converter factory is used.
export function register (registry) {
  const target = registry && typeof registry.register === 'function' ? registry : ConverterFactory
  target.register(RevealJsConverter, 'revealjs', 'reveal.js')
  SyntaxHighlighter.register(HighlightJsAdapter, 'highlightjs', 'highlight.js')
  return RevealJsConverter
}

export function getVersion () {
  return pkg.version
}

export { RevealJsConverter }
