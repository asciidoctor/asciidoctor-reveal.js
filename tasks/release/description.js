import { readFileSync, writeFileSync } from 'node:fs'
import path from 'node:path'
import { projectRootDirectory, requireVersion } from './common.js'

const releaseVersion = requireVersion('release:description')

const changelog = readFileSync(path.join(projectRootDirectory, 'CHANGELOG.md'), 'utf8')
const rx = new RegExp(`## ${releaseVersion}.*\\n(?<content>[\\s\\S]+?)\\n(?=## )`)
const content = rx.exec(changelog)?.groups?.content ?? ''
if (!content) {
  console.error(`Version ${releaseVersion} not found in CHANGELOG.md, release description will be empty!`)
}
writeFileSync(path.join(projectRootDirectory, 'dist', 'changelog.md'), content, 'utf8')