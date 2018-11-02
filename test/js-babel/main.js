import Asciidoctor from 'asciidoctor.js'
const asciidoctor = Asciidoctor()

// Babel will move the import statement at the top of the file.
// As a consequence, the reveal.js converter will be loaded before the initialization of Asciidoctor.js.
import 'asciidoctor-reveal.js'
// If we replace the import statement by a require statement then it's working.
// Another way to fix this issue is to lazily load the reveal.js converter.
//require('asciidoctor-reveal.js')

const attributes = { revealjsdir: 'node_modules/reveal.js@' }
const options = {
  safe: 'safe',
  backend: 'revealjs',
  attributes: attributes,
  header_footer: true
}

console.log(asciidoctor.convert('Hello *Babel*', options))
