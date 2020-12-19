const asciidoctor = require('@asciidoctor/core')()
const asciidoctorRevealjs = require('../dist/main.js')
//require('../dist/main.js')

const expect = require('expect.js')

// Register the reveal.js converter
asciidoctorRevealjs.register()

const options = {safe: 'safe', backend: 'revealjs', standalone: true}
const content = `= Title Slide

== Slide One

* Foo
* Bar
* World`

const result = asciidoctor.convert(content, options)

expect(result).to.contain('<script src="node_modules/reveal.js/js/reveal.js">')
expect(result).to.contain('<li><p>Foo</p></li>')

// verify version info
const pkg = require('../package.json')
const version = asciidoctorRevealjs.getVersion()
// RubyGems versions must use a slightly different pattern:
// https://guides.rubygems.org/patterns/#prerelease-gems
const RUBY_PRERELEASE_VERSION_RX = /(?<version>[0-9]+\.[0-9]+\.[0-9]+)(\.(?<preversionName>[a-z]+)(?<preversionNumber>[0-9]+))?/
let semVer = version
const prereleaseVersionFound = RUBY_PRERELEASE_VERSION_RX.exec(version)
if (prereleaseVersionFound &&
  prereleaseVersionFound.groups &&
  prereleaseVersionFound.groups.preversionName &&
  prereleaseVersionFound.groups.preversionNumber &&
  prereleaseVersionFound.groups.version) {
  semVer = `${prereleaseVersionFound.groups.version}-${prereleaseVersionFound.groups.preversionName}.${prereleaseVersionFound.groups.preversionNumber}`
}
expect(semVer).to.be(pkg.version)
