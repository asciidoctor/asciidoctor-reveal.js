// esbuild plugin used by the Single Executable Application (SEA) build.
//
// A SEA bundle is a single CommonJS file injected into the Node.js binary;
// there are no sibling files on disk at runtime. The converter (and the
// bundled Asciidoctor.js CLI) read a few data files lazily with
// `readFileSync(new URL('…', import.meta.url), 'utf8')` or
// `readFileSync(join(import.meta.dirname, …), 'utf8')`. Those paths resolve
// relative to the *bundle* once everything is concatenated, so the files are
// missing. This plugin reads them at build time and inlines their content as
// string literals, keeping the original source untouched for the regular
// (non-bundled) `node` execution.

import { readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'

// readFileSync(new URL('<relative>', import.meta.url), 'utf8')
const URL_READ =
  /readFileSync\(\s*new URL\(\s*(['"`])(.+?)\1\s*,\s*import\.meta\.url\s*\)\s*,\s*(['"`])utf-?8\3\s*\)/g

// readFileSync(join(import.meta.dirname, '<seg>', '<seg>', …), 'utf8')
const DIRNAME_READ =
  /readFileSync\(\s*join\(\s*import\.meta\.dirname\s*,\s*([^)]*?)\)\s*,\s*(['"`])utf-?8\2\s*\)/g

// Only scan the handful of files known to use those patterns; scanning the
// whole dependency tree would be wasteful and risk false positives.
const TARGETS = /(js[\\/]src[\\/]|asciidoctor[\\/]lib[\\/]cli\.js)/

function literal (filePath) {
  return JSON.stringify(readFileSync(filePath, 'utf8'))
}

export function inlineAssets () {
  return {
    name: 'inline-assets',
    setup (build) {
      build.onLoad({ filter: /\.[cm]?js$/ }, (args) => {
        if (!TARGETS.test(args.path)) return undefined
        let source = readFileSync(args.path, 'utf8')
        if (!source.includes('readFileSync')) return undefined
        const baseDir = dirname(args.path)
        source = source.replace(URL_READ, (_match, _q, relative) =>
          literal(resolve(baseDir, relative))
        )
        source = source.replace(DIRNAME_READ, (_match, segments) => {
          const parts = segments
            .split(',')
            .map((segment) => segment.trim().replace(/^['"`]|['"`]$/g, ''))
            .filter(Boolean)
          return literal(resolve(baseDir, ...parts))
        })
        return { contents: source, loader: 'js' }
      })
    }
  }
}