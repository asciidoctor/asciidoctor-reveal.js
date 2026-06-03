import { readFileSync, writeFileSync } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import process from 'node:process'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

const args = process.argv.slice(2)
const releaseVersion = args[0]

if (!releaseVersion) {
  console.log('Release version is undefined, please specify a version `npm run release:description 1.0.0`')
  process.exit(9)
}
const projectRootDirectory = path.join(__dirname, '..', '..')

const rx = new RegExp(`## ${releaseVersion}.*\\n(?<content>[\\s\\S]+?)\\n(?=## )`)
const changelog = readFileSync(path.join(projectRootDirectory, 'CHANGELOG.md'), 'utf8')
const changelogVersion = rx.exec(changelog)
let content
if (changelogVersion && changelogVersion.groups && changelogVersion.groups.content) {
  content = changelogVersion.groups.content
} else {
  content = ''
  console.error(`Version ${releaseVersion} not found in CHANGELOG.md, release description will be empty!`)
}
writeFileSync(path.join(projectRootDirectory, 'dist', 'changelog.md'), content, 'utf8')
