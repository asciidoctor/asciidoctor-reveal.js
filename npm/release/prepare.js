'use strict'
const childProcess = require('child_process')
const path = require('path')
const fs = require('fs')
const execModule = require('./exec.js')

const PRERELEASE_VERSION_RX = /(?<version>[0-9]+\.[0-9]+\.[0-9]+)(?<preversion>-[a-z]+\.[0-9]+)?/

const args = process.argv.slice(2)
const releaseVersion = args[0]

if (!releaseVersion) {
  console.error('Release version is undefined, please specify a version `npm run release:prepare 1.0.0`')
  process.exit(9)
}
console.log(`Release version: ${releaseVersion}`)
if (process.env.DRY_RUN) {
  console.warn('Dry run! To perform the release, run the command again without DRY_RUN environment variable')
}
const projectRootDirectory = path.join(__dirname, '..', '..')
try {
  childProcess.execSync('git diff-index --quiet HEAD --', {cwd: projectRootDirectory})
} catch (e) {
  console.error('Git working directory not clean')
  const status = childProcess.execSync('git status -s')
  process.stdout.write(status)
  process.exit(1)
}
const branchName = childProcess.execSync('git symbolic-ref --short HEAD', {cwd: projectRootDirectory}).toString('utf-8').trim()
if (branchName !== 'master') {
  console.error('Release must be performed on master branch')
  process.exit(1)
}
// update version in package.json
const pkgPath = path.join(projectRootDirectory, 'package.json')
const asciidoctorRevealPkg = require(pkgPath)
asciidoctorRevealPkg.version = releaseVersion
const pkgUpdated = JSON.stringify(asciidoctorRevealPkg, null, 2).concat('\n')
if (process.env.DRY_RUN) {
  console.debug(`Dry run! ${pkgPath} will be updated:\n${pkgUpdated}`)
} else {
  fs.writeFileSync(pkgPath, pkgUpdated)
}
// update version in lib/asciidoctor-revealjs/version.rb
const versionRbPath =  path.join(projectRootDirectory, 'lib', 'asciidoctor-revealjs', 'version.rb')
const versionRbContent = fs.readFileSync(versionRbPath, 'utf8')
// RubyGems versions must use a slightly different pattern:
// https://guides.rubygems.org/patterns/#prerelease-gems
let rubyReleaseVersion = releaseVersion
const prereleaseVersionFound = PRERELEASE_VERSION_RX.exec(releaseVersion)
if (prereleaseVersionFound &&
  prereleaseVersionFound.groups &&
  prereleaseVersionFound.groups.preversion &&
  prereleaseVersionFound.groups.version) {
  const rubyPrereleaseVersion = prereleaseVersionFound.groups.preversion.replace('-', '').replace('.', '');
  rubyReleaseVersion = `${prereleaseVersionFound.groups.version}.${rubyPrereleaseVersion}`
}
const versionRbUpdated = versionRbContent.replace(/VERSION = '([^']+)'/, `VERSION = '${rubyReleaseVersion}'`)
if (process.env.DRY_RUN) {
  console.debug(`Dry run! ${versionRbPath} will be updated:\n${versionRbUpdated}`)
} else {
  fs.writeFileSync(versionRbPath, versionRbUpdated)
}
execModule.execSync('bundle exec rake build', {cwd: projectRootDirectory})
execModule.execSync('git add -f lib/asciidoctor-revealjs/converter.rb', {cwd: projectRootDirectory})

// git commit and tag
execModule.execSync(`git commit -a -m "Prepare ${releaseVersion} release"`, {cwd: projectRootDirectory})
execModule.execSync(`git commit --allow-empty -m "Release ${releaseVersion}"`, {cwd: projectRootDirectory})
execModule.execSync(`git tag v${releaseVersion} -m "Version ${releaseVersion}"`, {cwd: projectRootDirectory})

console.info('To complete the release, you need to:')
console.info('[ ] push changes upstream: `git push origin master --tags`')
