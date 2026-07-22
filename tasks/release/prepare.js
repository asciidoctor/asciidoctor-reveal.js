import path from 'node:path'
import { readFileSync } from 'node:fs'
import process from 'node:process'
import { projectRootDirectory, execSync, writeFile, requireVersion, ensureCleanMainBranch } from './common.js'

const PRERELEASE_VERSION_RX = /(?<version>[0-9]+\.[0-9]+\.[0-9]+)(?<preversion>-[a-z]+\.[0-9]+)?/

const releaseVersion = requireVersion('release:prepare')
console.log(`Release version: ${releaseVersion}`)
if (process.env.DRY_RUN) {
  console.warn('Dry run! To perform the release, run the command again without DRY_RUN environment variable')
}
ensureCleanMainBranch('Release')

// update version in package.json
const pkgPath = path.join(projectRootDirectory, 'package.json')
const asciidoctorRevealPkg = JSON.parse(readFileSync(pkgPath, 'utf8'))
asciidoctorRevealPkg.version = releaseVersion
writeFile(pkgPath, JSON.stringify(asciidoctorRevealPkg, null, 2).concat('\n'))

// update version in lib/asciidoctor_revealjs/version.rb
// RubyGems versions must use a slightly different pattern:
// https://guides.rubygems.org/patterns/#prerelease-gems
let rubyReleaseVersion = releaseVersion
const prerelease = PRERELEASE_VERSION_RX.exec(releaseVersion)
if (prerelease?.groups?.preversion && prerelease.groups.version) {
  const rubyPrereleaseVersion = prerelease.groups.preversion.replace('-', '').replace('.', '')
  rubyReleaseVersion = `${prerelease.groups.version}.${rubyPrereleaseVersion}`
}
const versionRbPath = path.join(projectRootDirectory, 'lib', 'asciidoctor_revealjs', 'version.rb')
const versionRbContent = readFileSync(versionRbPath, 'utf8')
writeFile(versionRbPath, versionRbContent.replace(/VERSION = '([^']+)'/, `VERSION = '${rubyReleaseVersion}'`))

// git commit and tag
execSync(`git commit -a -m "Prepare ${releaseVersion} release"`, { cwd: projectRootDirectory })
execSync(`git commit --allow-empty -m "Release ${releaseVersion}"`, { cwd: projectRootDirectory })
execSync(`git tag v${releaseVersion} -m "Version ${releaseVersion}"`, { cwd: projectRootDirectory })

console.info('To complete the release, you need to:')
console.info('[ ] push changes upstream: `git push origin main --tags`')