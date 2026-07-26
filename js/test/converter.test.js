// Smoke test for the native JavaScript reveal.js converter.
// Run with: node --test js/test/   (Node >= 20)

import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { convert } from 'asciidoctor'
import { register, getVersion } from '../src/index.js'

const pkg = JSON.parse(readFileSync(new URL('../../package.json', import.meta.url), 'utf8'))

register()

test('converts a basic deck the reveal.js way', async () => {
  const content = `= Title Slide

== Slide One

* Foo
* Bar
* World`

  const result = await convert(content, { safe: 'safe', backend: 'revealjs', standalone: true })

  assert.ok(result.includes('<script src="node_modules/reveal.js/dist/reveal.js">'), 'reveal.js script tag is present')
  assert.ok(result.includes('<li><p>Foo</p></li>'), 'list item is rendered the reveal.js way')
  assert.ok(result.includes('<section class="title" data-state="title">'), 'title slide section is present')
  assert.ok(result.includes('<h2>Slide One</h2>'), 'slide title is present')
})

test('reports the package version', () => {
  assert.equal(getVersion(), pkg.version)
})

test('configures hljs before registering the reveal.js highlight plugin', async () => {
  // The reveal.js `highlight` plugin highlights every code block as soon as it
  // registers itself (Reveal.initialize() is already running by the time this
  // docinfo footer script runs, so late plugin registration triggers
  // highlighting immediately). hljs.configure({ ignoreUnescapedHTML: true })
  // must therefore run before Reveal.registerPlugin('highlight', ...), not
  // after: configuring hljs only after the plugin already highlighted every
  // block (the previous order) corrupts the line-numbers/highlight-lines
  // markup on every subsequent highlight pass, showing up as duplicated nested
  // <span> wrappers and washed-out/ungraded syntax colors (#525).
  const result = await convert('no code blocks here', {
    safe: 'safe', backend: 'revealjs', standalone: true, attributes: { 'source-highlighter': 'highlightjs' }
  })

  const configureIndex = result.indexOf('hljs.configure(')
  const registerPluginIndex = result.indexOf("Reveal.registerPlugin( 'highlight', Plugin )")

  assert.notEqual(configureIndex, -1)
  assert.notEqual(registerPluginIndex, -1)
  assert.ok(configureIndex < registerPluginIndex, 'hljs.configure() must run before the plugin registers itself')
  assert.ok(!result.includes('hljs.highlightAll()'), 'hljs.highlightAll() is redundant, the reveal.js plugin already highlights every block')
})

test('html5 backend gets the plain built-in highlightjs behavior', async () => {
  // Registering this adapter for 'highlightjs'/'highlight.js' overrides the built-in
  // highlight.js syntax highlighter for every backend, not just revealjs - the
  // SyntaxHighlighter registry has no notion of "per backend". Requiring this
  // package must not change how any other backend renders source blocks (#489).
  const source = '[source,ruby]\n----\nputs \'hi\'\n----'
  const result = await convert(source, {
    safe: 'safe', backend: 'html5', standalone: true, attributes: { 'source-highlighter': 'highlightjs' }
  })

  assert.ok(!result.includes('data-noescape'))
  assert.ok(result.includes('<pre class="highlightjs highlight"><code class="language-ruby hljs" data-lang="ruby">'))
})

test('toc omits titleless slides', async () => {
  const content = `= Example

== !
toc::[]

== Slide 1

content

== Slide 2

content

=== Sub slide

nested`

  const result = await convert(content, { safe: 'safe', backend: 'revealjs', standalone: false })

  assert.ok(!result.includes('>!<'))
  assert.ok(result.includes('<li><a href="#_slide_1">Slide 1</a></li>'))
  assert.ok(result.includes('<li><a href="#_sub_slide">Sub slide</a></li>'))
})

test('r-stack open block does not wrap content in a content div', async () => {
  // reveal.js's .r-stack CSS targets *direct* children (`.r-stack > *`) to stack
  // them on top of each other; the usual .content wrapper would put each image
  // one level too deep for that selector to reach (#520).
  const content = `[.r-stack]
--
image::before.png[]

image::after.png[]
--`
  const result = await convert(content, { safe: 'safe', backend: 'revealjs', standalone: false })

  assert.ok(result.includes('<div class="openblock r-stack"><div class="imageblock">'))
  assert.ok(!result.includes('<div class="openblock r-stack"><div class="content">'))
})

test('normal open block still gets a content div', async () => {
  const content = `[.custom]
--
Some content
--`
  const result = await convert(content, { safe: 'safe', backend: 'revealjs', standalone: false })

  assert.ok(result.includes('<div class="openblock custom"><div class="content">'))
})
