'use strict'
const childProcess = require('child_process')
const path = require('path')
const fs = require('fs')
const execModule = require('./exec.js')

const toSemVer = (version) => {
  let semVer
  if (typeof version === 'string') {
    // ignore pre-release (.dev and -dev)
    const fragments = version
      .replace(/\.dev/g, '')
      .replace(/-dev/g, '')
      .split('.')
    semVer = {
      major: parseInt(fragments[0]),
      minor: parseInt(fragments[1]),
      patch: parseInt(fragments[2])
    }
  } else {
    semVer = version
  }
  return semVer
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
  console.error('Preparing next version must be performed on master branch')
  process.exit(1)
}
// read current version from package.json
const pkgPath = path.join(projectRootDirectory, 'package.json')
const asciidoctorRevealPkg = require(pkgPath)
// compute next version
const currentVersion = asciidoctorRevealPkg.version
const currentSemVer = toSemVer(currentVersion)
// bump minor version
const nextSemVer = {
  major: currentSemVer.major,
  minor: currentSemVer.minor + 1,
  patch: currentSemVer.patch
}
const nextVersion = `${nextSemVer.major}.${nextSemVer.minor}.${nextSemVer.patch}-dev`

// update version in package.json
asciidoctorRevealPkg.version = nextVersion
const pkgUpdated = JSON.stringify(asciidoctorRevealPkg, null, 2).concat('\n')
if (process.env.DRY_RUN) {
  console.debug(`Dry run! ${pkgPath} will be updated:\n${pkgUpdated}`)
} else {
  fs.writeFileSync(pkgPath, pkgUpdated)
}

// update version in lib/asciidoctor-revealjs/version.rb
const versionRbPath =  path.join(projectRootDirectory, 'lib', 'asciidoctor-revealjs', 'version.rb')
const versionRbContent = fs.readFileSync(versionRbPath, 'utf8')
const versionRbUpdated = versionRbContent.replace(/VERSION = '([^']+)'/, `VERSION = '${nextVersion}'`)
if (process.env.DRY_RUN) {
  console.debug(`Dry run! ${versionRbPath} will be updated:\n${versionRbUpdated}`)
} else {
  fs.writeFileSync(versionRbPath, versionRbUpdated)
}

// update version in docs/antora.yml
const antoraYmlPath =  path.join(projectRootDirectory, 'docs', 'antora.yml')
const antoraYmlContent = fs.readFileSync(antoraYmlPath, 'utf8')
const antoraYmlUpdated = antoraYmlContent.replace(/version: '([^']+)'/, `version: '${nextSemVer.major}.${nextSemVer.minor}'`)
if (process.env.DRY_RUN) {
  console.debug(`Dry run! ${antoraYmlPath} will be updated:\n${antoraYmlUpdated}`)
} else {
  fs.writeFileSync(antoraYmlPath, antoraYmlUpdated)
}

// remove the converter (generated from the Slim templates) from the git tree (to avoid noise to the repo and `git status` noise)
execModule.execSync('git rm --cached lib/asciidoctor-revealjs/converter.rb', {cwd: projectRootDirectory})

// git commit
execModule.execSync(`git commit -a -m "Begin development on next release ${nextVersion}"`, {cwd: projectRootDirectory})

console.info('To complete, you need to:')
console.info('[ ] push changes upstream: `git push origin master`')
console.info(`[ ] create a branch from the latest tag: \`git checkout -b maint-${currentSemVer.major}.${currentSemVer.minor}.x v${currentVersion}\``)
console.info(`[ ] push the maintenance branch: \`git push origin maint-${currentSemVer.major}.${currentSemVer.minor}.x\``)
console.info(`[ ] update Antora playbook to add this branch: https://github.com/asciidoctor/docs.asciidoctor.org/edit/main/antora-playbook.yml`)
console.info(`[ ] submit a pull request downstream to update Asciidoctor reveal.js version in the Asciidoctor Docker Container`)
console.info(`  - modify the \`Dockerfile\`, \`Makefile\` and \`README.adoc\` in: https://github.com/asciidoctor/docker-asciidoctor`)
console.info(`[ ] submit a pull request downstream to update AsciidoctorJ reveal.js version`)
console.info(`  - modify \`gradle.properties\`, \`asciidoctorj-revealjs/gradle.properties\` and \`asciidoctorj-revealjs/build.gradle\` in: https://github.com/asciidoctor/asciidoctorj-reveal.js`)
