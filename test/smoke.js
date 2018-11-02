const asciidoctor = require('asciidoctor.js')()
const asciidoctorRevealjs = require('../dist/main.js')
//require('../dist/main.js')

const expect = require('expect.js')

// Register the reveal.js converter
const revealjsConverter = asciidoctorRevealjs.register()
const version = revealjsConverter.getVersion();

const attributes = {'revealjsdir': 'node_modules/reveal.js@'}
const options = {safe: 'safe', backend: 'revealjs', attributes: attributes, 'header_footer': true}
const content = `= Title Slide

== Slide One

* Foo
* Bar
* World`

const result = asciidoctor.convert(content, options)

expect(version).to.be('1.5.6')
expect(result).to.contain('<script src="node_modules/reveal.js/js/reveal.js">')
expect(result).to.contain('<li><p>Foo</p></li>')

