# reveal.js converter for Asciidoctor.js

A reveal.js converter for [Asciidoctor.js](https://github.com/asciidoctor/asciidoctor.js) that transforms an AsciiDoc document into an HTML5 presentation designed to be executed by the [reveal.js](https://revealjs.com) presentation framework.

## Install

Requires **Node.js >= 20**. `asciidoctor` is a required peer dependency (any `>=4.0.0 <5.0.0` release), so install it alongside the converter:

```sh
npm i --save asciidoctor @asciidoctor/reveal.js
```

## Command line

```sh
npx asciidoctor-revealjs presentation.adoc      # writes presentation.html
npx asciidoctor-revealjs -o - presentation.adoc # write to stdout
```

Run `npx asciidoctor-revealjs --help` for the full option list.

## JavaScript API

Asciidoctor.js 4.0 is an ESM package and its conversion functions are asynchronous, so use `import` and `await`:

```js
import { convertFile } from 'asciidoctor'
import { register } from '@asciidoctor/reveal.js'

register() // registers the revealjs / reveal.js backends and the highlight.js adapter

await convertFile('presentation.adoc', { safe: 'safe', backend: 'revealjs' })
```

## Documentation

For setup instructions and the AsciiDoc syntax used to write a presentation, see the [documentation](https://docs.asciidoctor.org/reveal.js-converter/latest/).

## License

MIT.
