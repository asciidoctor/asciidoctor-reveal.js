import Asciidoctor from 'asciidoctor.js'
const asciidoctor = Asciidoctor()

// Babel will move the import statement at the top of the file.
// As a consequence, the reveal.js converter will be loaded before the initialization of Asciidoctor.js.
//import 'asciidoctor-reveal.js'

// To workaround this issue, we use replace the import statement by a require statement.
require('asciidoctor-reveal.js')

// Please note that asciidoctor-reveal.js 2.0.0 supports lazy loading.
// The following should work with asciidoctor-reveal.js 2.0+
//import AsciidoctorReveal from 'asciidoctor-reveal.js'
//AsciidoctorReveal.register()

const attributes = { revealjsdir: 'node_modules/reveal.js@' }
const options = {
  safe: 'safe',
  backend: 'revealjs',
  attributes: attributes,
  header_footer: true
}

console.log(asciidoctor.convert('Hello *Babel*', options))
