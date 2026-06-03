import { readdirSync } from 'node:fs'
import path from 'node:path'
import log from 'bestikk-log'
import { convertFile } from '@asciidoctor/core'
import { register } from '../js/src/index.js'

const examplesDir = 'examples'

log.task('examples')

// Register the native reveal.js converter
register()

// Convert every example document using the reveal.js converter
const attributes = { revealjsdir: 'reveal.js' }
const options = { safe: 'safe', backend: 'revealjs', attributes, to_dir: examplesDir }

for (const filename of readdirSync(examplesDir)) {
  if (path.extname(filename) === '.adoc') {
    try {
      // convert handlers are async in Asciidoctor.js 4.0
      await convertFile(path.join(examplesDir, filename), options)
      log.info(`Successfully converted ${filename}`)
    } catch (err) {
      log.error(`Error converting ${filename}: ${err}`)
    }
  }
}
