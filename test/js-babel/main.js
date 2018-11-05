import Asciidoctor from 'asciidoctor.js'
const asciidoctor = Asciidoctor()

// BEFORE SUPPORT
// Babel will move the import statement at the top of the file.
// As a consequence, the reveal.js converter will be loaded before the initialization of Asciidoctor.js.
//import 'asciidoctor-reveal.js'

// NOW SUPPORTED
import AsciidoctorRevealjs from 'asciidoctor-reveal.js'
AsciidoctorRevealjs.register()

const attributes = { revealjsdir: 'node_modules/reveal.js@' }
const options = {
  safe: 'safe',
  backend: 'revealjs',
  attributes: attributes,
  header_footer: true
}

console.log(asciidoctor.convert('Hello *Babel*', options))
