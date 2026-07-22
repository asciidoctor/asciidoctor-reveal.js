import { describe, test } from 'node:test'
import assert from 'node:assert/strict'
import { rollUnreleased, extractNotes } from '../changelog.js'

const CHANGELOG_FIXTURE = `# Changelog

## main (unreleased)

### Enhancements

  * Something new

## 5.2.0 (2024-02-12)

### Enhancements

  * Old stuff
`

describe('rollUnreleased', () => {
  const rolled = rollUnreleased(CHANGELOG_FIXTURE, '5.3.0', '2026-07-22')

  test('inserts the dated section header for the new version', () => {
    assert.ok(rolled.includes('## 5.3.0 (2026-07-22)'))
  })

  test('keeps a fresh, empty "## main (unreleased)" section above it', () => {
    assert.match(rolled, /^## main \(unreleased\)\n\n## 5\.3\.0 \(2026-07-22\)$/m)
  })

  test('preserves the unreleased content under the new dated header', () => {
    assert.ok(rolled.includes('## 5.3.0 (2026-07-22)\n\n### Enhancements\n\n  * Something new'))
  })

  test('preserves earlier version sections unchanged', () => {
    assert.ok(rolled.includes('## 5.2.0 (2024-02-12)\n\n### Enhancements\n\n  * Old stuff'))
  })

  test('returns the content unchanged when there is no "## main (unreleased)" section', () => {
    const content = '# Changelog\n\n## 5.2.0 (2024-02-12)\n\nnothing else\n'
    assert.equal(rollUnreleased(content, '5.3.0', '2026-07-22'), content)
  })
})

describe('extractNotes', () => {
  test('extracts the section content for the given version', () => {
    assert.equal(extractNotes(CHANGELOG_FIXTURE, '5.2.0'), '### Enhancements\n\n  * Old stuff')
  })

  test('extracts the content of a freshly rolled version section', () => {
    const rolled = rollUnreleased(CHANGELOG_FIXTURE, '5.3.0', '2026-07-22')
    assert.equal(extractNotes(rolled, '5.3.0'), '### Enhancements\n\n  * Something new')
  })

  test('returns undefined when the version section is missing', () => {
    assert.equal(extractNotes(CHANGELOG_FIXTURE, '9.9.9'), undefined)
  })

  test('escapes regex-special characters in the version', () => {
    const content = '## main (unreleased)\n\n## 5.3.0-beta.1 (2026-07-22)\n\n### Enhancements\n\n  * Beta content\n\n## 5.2.0 (2024-02-12)\n'
    assert.equal(extractNotes(content, '5.3.0-beta.1'), '### Enhancements\n\n  * Beta content')
  })
})