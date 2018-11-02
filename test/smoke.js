const asciidoctor = require('asciidoctor.js')()
const asciidoctorRevealjs = require('../dist/main.js')
//require('../dist/main.js')

const expect = require('expect.js')

// Register the reveal.js converter
asciidoctorRevealjs.register()

const attributes = {'revealjsdir': 'node_modules/reveal.js@'}
const options = {safe: 'safe', backend: 'revealjs', attributes: attributes, 'header_footer': true}
const content = `= Title Slide

== Slide One

* Foo
* Bar
* World`

const result = asciidoctor.convert(content, options)

expect(asciidoctorRevealjs.getVersion()).to.be('1.1.4-dev')
expect(result).to.contain('<script src="node_modules/reveal.js/js/reveal.js">')
expect(result).to.contain('<li><p>Foo</p></li>')

