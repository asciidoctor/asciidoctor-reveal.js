import path from 'node:path'
import { readFileSync } from 'node:fs'
import { projectRootDirectory, execSync, writeFile, ensureCleanMainBranch } from './common.js'

// Parse a version into its major/minor/patch numbers, ignoring any pre-release (.dev and -dev).
const toSemVer = (version) => {
  const [major, minor, patch] = version
    .replace(/\.dev/g, '')
    .replace(/-dev/g, '')
    .split('.')
    .map((fragment) => parseInt(fragment))
  return { major, minor, patch }
}

ensureCleanMainBranch('Preparing next version')

// read current version from package.json
const pkgPath = path.join(projectRootDirectory, 'package.json')
const asciidoctorRevealPkg = JSON.parse(readFileSync(pkgPath, 'utf8'))
const currentVersion = asciidoctorRevealPkg.version
const currentSemVer = toSemVer(currentVersion)

// compute next version (bump minor)
const nextSemVer = { major: currentSemVer.major, minor: currentSemVer.minor + 1, patch: currentSemVer.patch }
const nextVersion = `${nextSemVer.major}.${nextSemVer.minor}.${nextSemVer.patch}-dev`

// update version in package.json
asciidoctorRevealPkg.version = nextVersion
writeFile(pkgPath, JSON.stringify(asciidoctorRevealPkg, null, 2).concat('\n'))

// update version in lib/asciidoctor_revealjs/version.rb
const versionRbPath = path.join(projectRootDirectory, 'lib', 'asciidoctor_revealjs', 'version.rb')
const versionRbContent = readFileSync(versionRbPath, 'utf8')
writeFile(versionRbPath, versionRbContent.replace(/VERSION = '([^']+)'/, `VERSION = '${nextVersion}'`))

// update version in docs/antora.yml
const antoraYmlPath = path.join(projectRootDirectory, 'docs', 'antora.yml')
const antoraYmlContent = readFileSync(antoraYmlPath, 'utf8')
writeFile(antoraYmlPath, antoraYmlContent.replace(/version: '([^']+)'/, `version: '${nextSemVer.major}.${nextSemVer.minor}'`))

// git commit
execSync(`git commit -a -m "Begin development on next release ${nextVersion}"`, { cwd: projectRootDirectory })

console.info('To complete, you need to:')
console.info('[ ] push changes upstream: `git push origin main`')
console.info(`[ ] create a branch from the latest tag: \`git checkout -b maint-${currentSemVer.major}.${currentSemVer.minor}.x v${currentVersion}\``)
console.info(`[ ] push the maintenance branch: \`git push origin maint-${currentSemVer.major}.${currentSemVer.minor}.x\``)
console.info(`[ ] update Antora playbook to add this branch: https://github.com/asciidoctor/docs.asciidoctor.org/edit/main/antora-playbook.yml`)
console.info(`[ ] submit a pull request downstream to update Asciidoctor reveal.js version in the Asciidoctor Docker Container`)
console.info(`  - modify the \`Dockerfile\`, \`Makefile\` and \`README.adoc\` in: https://github.com/asciidoctor/docker-asciidoctor`)
console.info(`[ ] submit a pull request downstream to update AsciidoctorJ reveal.js version`)
console.info(`  - modify \`gradle.properties\`, \`asciidoctorj-revealjs/gradle.properties\` and \`asciidoctorj-revealjs/build.gradle\` in: https://github.com/asciidoctor/asciidoctorj-reveal.js`)
