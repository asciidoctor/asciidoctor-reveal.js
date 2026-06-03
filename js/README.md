# Native JavaScript reveal.js converter

A native JavaScript implementation of the Asciidoctor reveal.js converter, built
on the **Asciidoctor.js 4.0** converter API (`asciidoctor@>=4.0.0-alpha.6`).

Asciidoctor.js 4.0 is a native JavaScript rewrite of Asciidoctor (no longer an
Opal transpilation), so this converter is a direct, idiomatic port of the Ruby
converter in `../lib/asciidoctor_revealjs/` rather than transpiled output.

## Requirements

- **Node.js >= 18** (the Asciidoctor.js 4.0 ESM build uses import attributes).
- `asciidoctor@>=4.0.0-alpha.6` (peer dependency).

This code ships as part of the `@asciidoctor/reveal.js` package: the repository's
root `package.json` declares `"type": "module"` and points `main` at
`js/src/index.js`, so there is no separate manifest under `js/`.

## Usage

```js
import { convert } from 'asciidoctor'
import { register } from '@asciidoctor/reveal.js'

register() // registers the `revealjs` / `reveal.js` backends and the highlight.js adapter

const html = await convert(input, { backend: 'revealjs', standalone: true })
```

`register(registry?)` accepts an optional object with a `register` method;
otherwise the global converter factory is used. Conversion is asynchronous in
Asciidoctor.js 4.0, so `convert`/`convertFile` return a `Promise`.

## Command line

`bin/asciidoctor-revealjs` reuses the CLI from the `asciidoctor` package
(`asciidoctor/cli`), which is ESM and core-4.0 compatible. The bin just defaults
the backend to `revealjs`, registers the converter and overrides the version
string (`Options`/`Invoker` subclasses):

```sh
node js/bin/asciidoctor-revealjs slides.adoc            # writes slides.html
node js/bin/asciidoctor-revealjs -o - slides.adoc       # write to stdout
node js/bin/asciidoctor-revealjs -s -a icons=font in.adoc
cat slides.adoc | node js/bin/asciidoctor-revealjs -    # read from stdin
```

Run `--help` for the full option list. The standalone `@asciidoctor/cli` package
is **not** used — it is CommonJS and still calls the removed `asciidoctor()`
3.x factory; the `asciidoctor` meta package bundles core 4.0 + an ESM CLI instead.

## Layout

| File | Role |
|------|------|
| `src/index.js` | `register()` / `getVersion()` entry point |
| `src/converter.js` | the `RevealJsConverter` (all `convert_*` handlers + helpers) |
| `src/footnotes.js` | per-slide / per-section footnote numbering |
| `src/reveal-js-options.js` | `Reveal.initialize(...)` options + stretch helpers |
| `src/stylesheet.js` | embedded compatibility CSS |
| `src/highlightjs.js` | reveal.js-tailored highlight.js syntax highlighter |
| `data/compatibility.css` | source of the embedded CSS |
| `data/highlight-plugin.js` | reveal.js highlight plugin source (verbatim) |

## Parity

The output is validated **byte-for-byte** against the Ruby converter. Of the 72
presentations in `../examples`, 65 are identical. The remaining differences are
**not** in this converter:

- `admonitions*.adoc` — Asciidoctor.js 4.0-alpha sets `textlabel` to the boolean
  `true` (instead of the caption string) when a block uses `caption='…'`.
- `release-4.1.adoc` — externalized footnotes defined via document attributes
  (`:fn-x: footnote:…[]`) and reused; depends on the alpha's attribute
  substitution timing.
- `source-{coderay,pygments,rouge,prettify}.adoc` — third-party syntax
  highlighters provided by Asciidoctor core (only `highlightjs` is customised by
  this converter, and it is byte-identical).

### Notes on the 4.0-alpha core

- Convert handlers are **async** (`await node.content()`); per-slide footnote
  state must be mutated in document order, so vertical slides/blocks are
  converted sequentially (never with `Promise.all`).

## Test

```sh
npm test            # node --test js/test/  (Node >= 18)
```

`converter.test.js` is a quick smoke test; `examples.test.js` converts every
presentation in `../examples` and diffs it against the Ruby converter (requires
Ruby/bundler — the whole suite is skipped otherwise). Presentations that cannot
match byte-for-byte (the parity gaps above) are individually skipped with a
reason, so the suite stays green.
