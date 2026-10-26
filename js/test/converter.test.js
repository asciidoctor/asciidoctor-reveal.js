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

test('table rowstep option applies fragment to each body row', async () => {
  const content = `[%rowstep,cols="1,1",options=header]
|===
|Name |Category

|Firefox |Browser
|Chrome |Browser
|===`
  const result = await convert(content, { safe: 'safe', backend: 'revealjs', standalone: false })

  assert.ok(result.includes('<thead><tr><th'))
  assert.ok(!result.includes('<thead><tr class="fragment">'))
  assert.equal(result.split('<tr class="fragment">').length - 1, 2)
})

test('table without rowstep option has plain rows', async () => {
  const content = `[cols="1,1",options=header]
|===
|Name |Category

|Firefox |Browser
|===`
  const result = await convert(content, { safe: 'safe', backend: 'revealjs', standalone: false })

  assert.ok(!result.includes('class="fragment"'))
})

test('collapsible example block renders as a details element', async () => {
  const content = `[%collapsible]
====
Hidden content.
====`
  const result = await convert(content, { safe: 'safe', backend: 'revealjs', standalone: false })

  assert.ok(result.includes('<details><summary class="title">Details</summary><div class="content">'))
  assert.ok(!result.includes('exampleblock'))
})

test('collapsible example block uses its title as the summary', async () => {
  const content = `[%collapsible]
.Custom summary
====
Hidden content.
====`
  const result = await convert(content, { safe: 'safe', backend: 'revealjs', standalone: false })

  assert.ok(result.includes('<summary class="title">Custom summary</summary>'))
})

test('collapsible example block with open option starts expanded', async () => {
  const content = `[%collapsible%open]
====
Visible content.
====`
  const result = await convert(content, { safe: 'safe', backend: 'revealjs', standalone: false })

  assert.ok(result.includes('<details open>'))
})

test('non-collapsible example block is unaffected', async () => {
  const content = `====
Regular content.
====`
  const result = await convert(content, { safe: 'safe', backend: 'revealjs', standalone: false })

  assert.ok(result.includes('<div class="exampleblock">'))
  assert.ok(!result.includes('<details'))
})

test('numbers the footnotes of a slide in document order', async () => {
  // List item text is substituted before the slides are converted, so a footnote in a list
  // item must not be numbered ahead of a footnote in a paragraph above it.
  const content = `= Deck

== Slide

Paragraph.footnote:[First]

* Item.footnote:[Second]
* Again.footnote:first[Third]
* Reused.footnote:first[]`

  const result = await convert(content, { safe: 'safe', backend: 'revealjs' })

  assert.ok(result.includes('<p>Paragraph.<sup class="footnote">[<span class="footnote" title="View footnote.">1</span>]</sup></p>'))
  assert.ok(result.includes('<li><p>Item.<sup class="footnote">[<span class="footnote" title="View footnote.">2</span>]</sup></p></li>'))
  assert.ok(result.includes('<li><p>Reused.<sup class="footnoteref">[<span class="footnote" title="View footnote.">3</span>]</sup></p></li>'))
  assert.ok(result.includes('<div class="footnotes"><div class="footnote">1. First</div><div class="footnote">2. Second</div><div class="footnote">3. Third</div></div>'))
})

test('lists the text of a footnote defined above a reference in a list item', async () => {
  // The reference in the list item is substituted before the definition in the paragraph above it.
  const content = `= Deck

== Slide

Paragraph.footnote:x[Definition]

* Item.footnote:x[]`

  const result = await convert(content, { safe: 'safe', backend: 'revealjs' })

  assert.ok(result.includes('<div class="footnotes"><div class="footnote">1. Definition</div></div>'))
})

test('numbers the footnotes of an embedded document without sections in document order', async () => {
  // List item and table cell text is substituted before the paragraph above them.
  const content = `Para footnote:[p]

* item footnote:[li]

|===
|cell footnote:[c]
|===`

  const result = await convert(content, { safe: 'safe', backend: 'revealjs', standalone: false })

  assert.ok(result.includes('<p>Para <sup class="footnote">[<span class="footnote" title="View footnote.">1</span>]</sup></p>'))
  assert.ok(result.includes('<li><p>item <sup class="footnote">[<span class="footnote" title="View footnote.">2</span>]</sup></p></li>'))
  assert.ok(result.includes('<p class="tableblock">cell <sup class="footnote">[<span class="footnote" title="View footnote.">3</span>]</sup></p>'))
  assert.ok(result.includes('<div id="footnotes"><hr><div class="footnote" id="_footnote_1"><a href="#_footnoteref_1">1</a>. p</div><div class="footnote" id="_footnote_2"><a href="#_footnoteref_2">2</a>. li</div><div class="footnote" id="_footnote_3"><a href="#_footnoteref_3">3</a>. c</div></div>'))
  assert.ok(!result.includes('\u0001'), 'no footnote placeholder leaks into the output')
})

test('numbers the footnotes of a deck without sections in document order', async () => {
  // The block title is substituted before the paragraph above it.
  const content = `= Deck

Para footnote:[p]

.Title footnote:[t]
----
code
----`

  const result = await convert(content, { safe: 'safe', backend: 'revealjs', standalone: true })

  assert.ok(result.includes('<p>Para <sup class="footnote">[<span class="footnote" title="View footnote.">1</span>]</sup></p>'))
  assert.ok(result.includes('<div class="title">Title <sup class="footnote">[<span class="footnote" title="View footnote.">2</span>]</sup></div>'))
  assert.ok(!result.includes('\u0001'), 'no footnote placeholder leaks into the output')
})

test('lists the footnotes of an AsciiDoc table cell on its slide', async () => {
  // AsciiDoc table cells are converted before the slides.
  const content = `= Deck

== Slide

Para footnote:[p]

|===
a|cell footnote:[x]
|===`

  const result = await convert(content, { safe: 'safe', backend: 'revealjs', standalone: true })

  assert.ok(result.includes('<p>cell <sup class="footnote">[<span class="footnote" title="View footnote.">2</span>]</sup></p></div><div id="footnotes"><hr><div class="footnote" id="_footnote_2"><a href="#_footnoteref_2">2</a>. x</div></div>'))
  assert.ok(result.includes('<div class="footnotes"><div class="footnote">1. p</div><div class="footnote">2. x</div></div></section>'))
  assert.ok(!result.includes('\u0001'), 'no footnote placeholder leaks into the output')
})

test('numbers the footnotes listed at the end of an embedded deck across slides', async () => {
  const content = `== First

One footnote:[one]

== Second

* item footnote:[two]`

  const result = await convert(content, { safe: 'safe', backend: 'revealjs', standalone: false })

  assert.ok(result.includes('<li><p>item <sup class="footnote">[<span class="footnote" title="View footnote.">1</span>]</sup></p></li>'))
  assert.ok(result.includes('<div class="footnotes"><div class="footnote">1. two</div></div></section>'))
  assert.ok(result.includes('<div id="footnotes"><hr><div class="footnote" id="_footnote_1"><a href="#_footnoteref_1">1</a>. one</div><div class="footnote" id="_footnote_2"><a href="#_footnoteref_2">2</a>. two</div></div>'))
})

test('lists the footnotes of an embedded document in document order, before and in the slides', async () => {
  // The slides are converted (and number their footnotes) before the content around them was resolved.
  const content = `Para.footnote:[p]

* Item.footnote:[li]

== Slide

Body.footnote:[b]`

  const result = await convert(content, { safe: 'safe', backend: 'revealjs', standalone: false })

  assert.ok(result.includes('<div class="footnote" id="_footnote_1"><a href="#_footnoteref_1">1</a>. p</div><div class="footnote" id="_footnote_2"><a href="#_footnoteref_2">2</a>. li</div><div class="footnote" id="_footnote_3"><a href="#_footnoteref_3">3</a>. b</div>'))
})
