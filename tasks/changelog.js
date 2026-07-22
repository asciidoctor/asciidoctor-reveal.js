#!/usr/bin/env node
// Changelog automation for the release workflow.
//
// Usage:
//   node tasks/changelog.js release <version>   Roll the "## main (unreleased)" section into a
//                                                dated "## <version> (YYYY-MM-DD)" section and
//                                                start a fresh, empty "## main (unreleased)" section.
//   node tasks/changelog.js notes <version>      Print the "## <version>" section to stdout, used
//                                                as the GitHub release notes.
//
// CHANGELOG.md is already Markdown, so unlike some sibling Asciidoctor projects this doesn't
// need an AsciiDoc-to-Markdown conversion step.

import { readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import process from 'node:process'

const changelogPath = join(import.meta.dirname, '..', 'CHANGELOG.md')

// Renames "## main (unreleased)" to a dated "## <version> (<date>)" section and starts a fresh,
// empty "## main (unreleased)" section above it. Returns the content unchanged if that section
// isn't found.
export const rollUnreleased = (content, version, date) =>
  content.replace(/^## main \(unreleased\)$/m, `## main (unreleased)\n\n## ${version} (${date})`)

// Extracts the "## <version> ..." section content (excluding its own heading and the next
// section's), or undefined if that section doesn't exist. Works for the last section in the
// file too, where there is no next heading to stop at.
export const extractNotes = (content, version) => {
  const escapedVersion = version.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  // `(?![\s\S])` (rather than `$`) asserts the true end of the string, since `$` would also
  // match at every line break under the `m` flag needed for the `^` header anchor.
  const rx = new RegExp(`^## ${escapedVersion}.*\\n(?<content>[\\s\\S]*?)(?=\\n## |(?![\\s\\S]))`, 'm')
  const notes = rx.exec(content)?.groups?.content
  return notes ? notes.trim() : undefined
}

// Entry point — only runs when executed directly, not when imported by tests
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [command, version] = process.argv.slice(2)
  if (!version || !['release', 'notes'].includes(command)) {
    console.error('Usage: node tasks/changelog.js <release|notes> <version>')
    process.exit(9)
  }

  const content = readFileSync(changelogPath, 'utf8')

  if (command === 'release') {
    const releaseDate = new Date().toISOString().slice(0, 10)
    const updated = rollUnreleased(content, version, releaseDate)
    if (updated === content) {
      console.error('Section "## main (unreleased)" not found in CHANGELOG.md')
      process.exit(1)
    }
    writeFileSync(changelogPath, updated)
  } else {
    const notes = extractNotes(content, version)
    if (!notes) {
      console.error(`Version ${version} not found in CHANGELOG.md, release notes will be empty!`)
    }
    process.stdout.write(`${notes ?? ''}\n`)
  }
}