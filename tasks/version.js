#!/usr/bin/env node
// Version automation for the release workflow.
//
// Usage:
//   node tasks/version.js release <version>   Set the release version in package.json and
//                                              lib/asciidoctor_revealjs/version.rb.
//   node tasks/version.js next <version>       Begin the next development cycle: set the given
//                                              (already -dev-suffixed) version in package.json
//                                              and lib/asciidoctor_revealjs/version.rb, and its
//                                              major.minor in docs/antora.yml. Run this locally
//                                              and push the result yourself; the version isn't
//                                              computed automatically since the next release
//                                              isn't always a minor bump.

import { readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import process from 'node:process'

const projectRootDirectory = join(import.meta.dirname, '..')
const pkgPath = join(projectRootDirectory, 'package.json')
const versionRbPath = join(projectRootDirectory, 'lib', 'asciidoctor_revealjs', 'version.rb')
const antoraYmlPath = join(projectRootDirectory, 'docs', 'antora.yml')

// RubyGems versions must use a slightly different pattern for pre-releases:
// https://guides.rubygems.org/patterns/#prerelease-gems
export const toRubyVersion = (version) => {
  const match = /^(?<version>[0-9]+\.[0-9]+\.[0-9]+)(?<preversion>-[a-z]+\.[0-9]+)?$/.exec(version)
  return match?.groups?.preversion
    ? `${match.groups.version}.${match.groups.preversion.replace('-', '').replace('.', '')}`
    : version
}

// The docs/antora.yml `version:` value (major.minor only) for a given package version.
export const antoraVersion = (version) => {
  const [, major, minor] = /^([0-9]+)\.([0-9]+)/.exec(version)
  return `${major}.${minor}`
}

const writeVersion = (version, rubyVersion) => {
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf8'))
  pkg.version = version
  writeFileSync(pkgPath, JSON.stringify(pkg, null, 2).concat('\n'))

  const versionRb = readFileSync(versionRbPath, 'utf8')
  writeFileSync(versionRbPath, versionRb.replace(/VERSION = '([^']+)'/, `VERSION = '${rubyVersion}'`))
}

// Entry point — only runs when executed directly, not when imported by tests
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [command, version] = process.argv.slice(2)
  if (command === 'release') {
    if (!version) {
      console.error('Usage: node tasks/version.js release <version>')
      process.exit(9)
    }
    writeVersion(version, toRubyVersion(version))
  } else if (command === 'next') {
    if (!version) {
      console.error('Usage: node tasks/version.js next <version>')
      process.exit(9)
    }
    writeVersion(version, version)

    const antoraYml = readFileSync(antoraYmlPath, 'utf8')
    writeFileSync(antoraYmlPath, antoraYml.replace(/version: '([^']+)'/, `version: '${antoraVersion(version)}'`))
  } else {
    console.error('Usage: node tasks/version.js <release|next> <version>')
    process.exit(9)
  }
}