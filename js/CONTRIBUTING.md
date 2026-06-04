# Contributor notes

Internal notes for working on the native JavaScript converter.
For installation and usage, see the [root README](../README.md) and the [project documentation](https://docs.asciidoctor.org/reveal.js-converter/latest/).

This converter is built on the **Asciidoctor.js 4.0** converter API, a native  JavaScript rewrite of Asciidoctor (no longer an Opal transpilation),
so it is a direct, idiomatic port of the Ruby converter in `../lib/asciidoctor_revealjs/` rather than transpiled output.

It ships as part of the `@asciidoctor/reveal.js` package:
the repository's root `package.json` declares `"type": "module"` and points `main` at `js/src/index.js`, so there is no separate manifest under `js/`.

## Layout

| File                          | Role                                                                              |
|-------------------------------|-----------------------------------------------------------------------------------|
| `src/index.js`                | `register()` / `getVersion()` entry point                                         |
| `src/converter.js`            | the `RevealJsConverter` (all `convert_*` handlers + helpers)                      |
| `src/footnotes.js`            | per-slide / per-section footnote numbering                                        |
| `src/reveal-js-options.js`    | `Reveal.initialize(...)` options + stretch helpers                                |
| `src/stylesheet.js`           | embedded compatibility CSS                                                        |
| `src/highlightjs.js`          | reveal.js-tailored highlight.js syntax highlighter                                |
| `../data/compatibility.css`   | source of the embedded CSS (shared with the Ruby implementation)                  |
| `../data/highlight-plugin.js` | reveal.js highlight plugin source, verbatim (shared with the Ruby implementation) |

## Parity

The output is validated **byte-for-byte** against the Ruby converter.
The remaining differences are **not** in this converter:

- `source-{coderay,pygments,rouge,prettify}.adoc` — third-party syntax highlighters provided by Asciidoctor core (only `highlightjs` is customized by this converter, and it is byte-identical).

### Notes on the 4.0 core

- Convert handlers are **async** (`await node.content()`);
per-slide footnote state must be mutated in document order, so vertical slides/blocks are converted sequentially (never with `Promise.all`).

## Test

```sh
npm test            # node --test js/test/  (Node >= 20)
```

`converter.test.js` is a quick smoke test; `examples.test.js` converts every presentation in `../examples` and diffs it against the Ruby converter (requires Ruby/bundler — the whole suite is skipped otherwise).
Presentations that cannot match byte-for-byte (the parity gaps above) are individually skipped with a reason, so the suite stays green.
