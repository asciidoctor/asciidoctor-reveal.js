// Smoke test for the native JavaScript reveal.js converter.
// Run with: node --test js/test/   (Node >= 20)

import { test } from 'node:test'
import assert from 'node:assert/strict'
import { convert } from 'asciidoctor'
import { register, getVersion } from '../src/index.js'

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
  assert.equal(getVersion(), '5.3.0-dev')
})
