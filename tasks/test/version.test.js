import { describe, test } from 'node:test'
import assert from 'node:assert/strict'
import { toRubyVersion, antoraVersion } from '../version.js'

describe('toRubyVersion', () => {
  test('leaves a final version unchanged', () => {
    assert.equal(toRubyVersion('5.3.0'), '5.3.0')
  })

  test('converts a beta pre-release to the RubyGems pre-release pattern', () => {
    assert.equal(toRubyVersion('5.3.0-beta.1'), '5.3.0.beta1')
  })

  test('converts an alpha pre-release to the RubyGems pre-release pattern', () => {
    assert.equal(toRubyVersion('4.0.0-alpha.6'), '4.0.0.alpha6')
  })

  test('leaves a -dev version unchanged (not a RubyGems pre-release pattern)', () => {
    assert.equal(toRubyVersion('5.4.0-dev'), '5.4.0-dev')
  })
})

describe('antoraVersion', () => {
  test('keeps only the major.minor of a version', () => {
    assert.equal(antoraVersion('5.4.0-dev'), '5.4')
  })

  test('works with a final version too', () => {
    assert.equal(antoraVersion('5.3.0'), '5.3')
  })
})