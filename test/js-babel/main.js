import Asciidoctor from '@asciidoctor/core'
import AsciidoctorReveal from '@asciidoctor/reveal.js'

const asciidoctor = Asciidoctor()
AsciidoctorReveal.register()

const attributes = { revealjsdir: 'node_modules/reveal.js@' }
const options = {
  safe: 'safe',
  backend: 'revealjs',
  attributes: attributes,
  header_footer: true
}

console.log(asciidoctor.convert('Hello *Babel*', options))
