// Parity test: every presentation in ../../examples is converted with the native
// JavaScript converter and compared byte-for-byte against the Ruby converter
// (the reference implementation, invoked through `bundle exec ruby`).
//
// Run with: node --test js/test/   (Node >= 18, Ruby/bundler available)
//
// The whole suite is skipped when Ruby/bundler is unavailable. Individual
// presentations that cannot match byte-for-byte (upstream 4.0-alpha bugs or
// third-party syntax highlighters) are skipped with an explicit reason.

import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readdirSync } from 'node:fs'
import { execFileSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join, resolve } from 'node:path'
import { convertFile } from '@asciidoctor/core'
import { register } from '../src/index.js'

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..')
const examplesDir = join(repoRoot, 'examples')
const REVEALJSDIR = 'node_modules/reveal.js'

// Presentations whose output cannot match the Ruby converter byte-for-byte. These
// differences are NOT in this converter — they are upstream Asciidoctor.js 4.0-alpha
// bugs or third-party syntax highlighters provided by Asciidoctor core.
const SKIP = {
  'admonitions.adoc': "Asciidoctor.js 4.0-alpha drops caption='…' (textlabel becomes the boolean true)",
  'admonitions-icons.adoc': "Asciidoctor.js 4.0-alpha drops caption='…' (textlabel becomes the boolean true)",
  'release-4.1.adoc': 'externalized footnote reuse depends on the alpha attribute-substitution timing',
  'source-coderay.adoc': 'third-party syntax highlighter provided by Asciidoctor core (only highlightjs is ported)',
  'source-prettify.adoc': 'third-party syntax highlighter provided by Asciidoctor core (only highlightjs is ported)',
  'source-pygments.adoc': 'third-party syntax highlighter provided by Asciidoctor core (only highlightjs is ported)',
  'source-rouge.adoc': 'third-party syntax highlighter provided by Asciidoctor core (only highlightjs is ported)'
}

register()

function rubyAvailable () {
  try {
    execFileSync('bundle', ['exec', 'ruby', '-e', "require './lib/asciidoctor_revealjs'"], { cwd: repoRoot, stdio: 'ignore' })
    return true
  } catch {
    return false
  }
}

function rubyConvert (file) {
  const script = `require './lib/asciidoctor_revealjs'; print Asciidoctor.convert_file(${JSON.stringify(file)}, safe: :safe, backend: 'revealjs', standalone: true, to_file: false, attributes: {'revealjsdir' => ${JSON.stringify(REVEALJSDIR)}})`
  return execFileSync('bundle', ['exec', 'ruby', '-e', script], { cwd: repoRoot, maxBuffer: 64 * 1024 * 1024 }).toString('utf8')
}

const haveRuby = rubyAvailable()
const files = readdirSync(examplesDir).filter((f) => f.endsWith('.adoc')).sort()

for (const filename of files) {
  const reason = SKIP[filename] ?? (haveRuby ? null : 'Ruby/bundler is not available for the reference output')
  test(`examples/${filename} matches the Ruby converter`, { skip: reason ?? false }, async () => {
    const file = join(examplesDir, filename)
    const expected = rubyConvert(file)
    const actual = await convertFile(file, {
      safe: 'safe',
      backend: 'revealjs',
      standalone: true,
      to_file: false,
      attributes: { revealjsdir: REVEALJSDIR }
    })
    assert.equal(actual, expected)
  })
}
