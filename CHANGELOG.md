# Changelog

This document provides a high-level view of the changes introduced in Asciidoctor reveal.js by release.
For a detailed view of what has changed, refer to the [commit history](https://github.com/asciidoctor/asciidoctor-reveal.js/commits/master) on GitHub.

## master (unreleased)

### Upgrade considerations

 * Plugin `marked` has been removed in reveal.js 4.0.0 and plugin `markdown` has been disabled. 
   As a result, the `revealjs_plugin_markdown` and `revealjs_plugin_marked` attributes have no effect anymore.
 * `revealjs_plugins` and `revealjs_plugins_configuration` are replaced by [Docinfo files](https://docs.asciidoctor.org/asciidoctor/latest/docinfo/).

**Before**

_presentation.adoc_
```adoc
= Third-party Plugins
:revealjs_plugins: examples/revealjs-plugins.js
:revealjs_plugins_configuration: examples/revealjs-plugins-conf.js

// ...
```
_revealjs-plugin.js_
```js
{ src: 'revealjs-plugins/reveal.js-menu/menu.js' },
{ src: 'revealjs-plugins/chalkboard/chalkboard.js' }
```
_revealjs-plugin-conf.js_
```js
menu: {
  side: 'right',
  openButton: false
},
keyboard: {
  67: function() { RevealChalkboard.toggleNotesCanvas() },
  66: function() { RevealChalkboard.toggleChalkboard() }
},
```

**After**

_presentation.adoc_
```adoc
= Third-party Plugins
:docinfo: private

// ...
```

_presentation-docinfo-footer.html_
```html
<script src="revealjs-plugins/menu/menu.js"></script>
<link rel="stylesheet" href="revealjs-plugins/chalkboard/style.css">
<script src="revealjs-plugins/chalkboard/plugin.js"></script>
<script>
  Reveal.configure({
    menu: {
      side: 'right',
      openButton: false
    },
    keyboard: {
      67: function() { RevealChalkboard.toggleNotesCanvas() },
      66: function() { RevealChalkboard.toggleChalkboard() }
    }
  })
  Reveal.registerPlugin(RevealMenu)
  Reveal.registerPlugin(RevealChalkboard)
</script>
```

 * If you are using third party plugins (such as chalkboard), please upgrade to the latest version.

### Bug Fixes

 * Include Rouge stylesheet when `:source-highlighter: rouge is present and when there's a least one source block.
 * Fix quotation marks and apostrophes
 * Fix subscripts erroneously mapped to superscripts

### Enhancements

 * Upgrade to reveal.js 4.1.2 (#370)
 * Add support for the Auto-Animate feature (#439)
 * Add support for the built-in search plugin (#441)
   * You can enable this plugin using `:revealjs_plugin_search: enabled`.
 * Upgrade MathJax to version 3.2.0
 * Display all the authors (inclusing their email addresses)
 * Upgrade development dependencies
   * Bump `path-parse` from 1.0.6 to 1.0.7 in /test/js-babel
   * Bump `path-parse` from 1.0.6 to 1.0.7
   * Bump `glob-parent` from 5.1.0 to 5.1.2 
   * Bump `lodash` from 4.17.19 to 4.17.21 in /test/js-babel
   * Bump `y18n` from 4.0.0 to 4.0.1
 * Drop `thread_safe` and `concurrent-ruby` dependencies
 * Add favicon to HTML if its attribute is present in AsciiDoc

### Documentation

 * Add link to https://asciidoctor-revealjs-examples.netlify.app/ in the documentation
 * Mention in the documentation that `revealjsdir` can be a CDN
 * Add maintenance branch procedure
 * Add downstream projects update procedure

## 4.1.0 (2020-12-19)

### Upgrade considerations

  * When a `background-video` attribute points to a file, that file is now looked up relative to the `imagesdir` document attribute.
    This new behavior aligns with what images and video macros already did.
    Existing slide decks using both `imagesdir` and `background-video` will need to move some files around.
    See [#356](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/356) for details.

### Enhancements

  * Introduced a `step` attribute to control the display order of elements
  * `%step` option can now be used on most blocks
  * Added `revealjs_disablelayout` attribute to disable layout ([#381](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/381))
  * Added support for Font Awesome icon sets using the `set`.
    For instance: `icon:font-awesome-flag[set=fab]` ([#393](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/393))
  * Upgraded Font Awesome to 5.15.1
  * Introduced an attribute to configure Font Awesome version `font-awesome-version` ([#392](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/392))
  * Added support for data attributes using AsciiDoc attributes prefixed by `data-` ([#241](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/241))
  * Added text alignment options to our _columns layout_ feature: `has-text-left`, `has-text-right` and `has-text-justified`.
    See [#354](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/354) for details.
  * Added a `mathjaxdir` attribute to control where MathJax is loaded from ([#350](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/350))
  * MathJax updated to version 2.7.6 (
    [#355](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/355),
    [#361](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/361))
  * Added new examples: MathJax, MathJax-CDN (
    [#350](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/350),
    [#359](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/359))
  * Documentation improvements (
    [#349](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/349),
    [#351](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/351),
    [#371](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/371),
    [#374](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/374))

### Compliance

  * Added support for footnotes ([#30](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/30))
  * Added support for built-in text alignments: `text-left`, `text-right`, `text-center` and `text-justify` ([#380](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/380))
  * `autoslide` attribute is now supported at the slide level (
    [#367](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/367),
    [#368](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/368))
  * Implemented the `muted` option for the video macro for YouTube and Vimeo ([#358](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/358))
  * `background-video` paths are now resolved using `media_uri` ([#356](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/356))

### Bug Fixes

  * Fixed a padding issue in _columns layout_ ([#372](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/372))
  * `autoplay` option fixed for YouTube and Vimeo videos ([#357](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/357))
  * Removed image resizing behavior when columns are wrapped in _columns layout_ feature (
    [#353](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/353),
    [#360](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/360))

### Infrastructure

  * Migrated CI jobs to GitHub Actions
  * Added Windows in CI build
  * Upgraded `asciidoctor-doctest` to v2.0.0.beta.7
  * Documentation migrated to Antora
  * Added an integration with [Netlify](https://www.netlify.com) to host specific slide deck examples (
    [#336](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/336),
    [#346](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/346))

### Release meta

* Released on: 2020-12-19
* Released by: [Guillaume Grossetie](https://github.com/mogztter)

[git tag](https://github.com/asciidoctor/asciidoctor-reveal.js/releases/tag/v4.1.0) |
[full diff](https://github.com/asciidoctor/asciidoctor-reveal.js/compare/v4.0.1...v4.1.0) |
[milestone](https://github.com/asciidoctor/asciidoctor-reveal.js/milestone/11)

### Credits

Thanks to the following people who contributed to this release:

[Adrian Kosmaczewski](https://github.com/akosma),
[Dan Allen](https://github.com/mojavelinux),
[Guillaume Grossetie](https://github.com/mogztter),
[Olivier Bilodeau](https://github.com/obilodeau) and
[Romain Quinio](https://github.com/rquinio).


## 4.0.1 (2020-02-18)

Repackage for NPM.


## 4.0.0 (2020-02-18)

A major release with a ton of improvements!
All of reveal.js 3.8.0-3.9.2 new features are supported.
Added a new set of column layout options for quick slides design.
Highlight.js support improved.
Easier templates customizations.
New Java / JVM toolchain via [AsciidoctorJ-reveal.js](https://github.com/asciidoctor/asciidoctorj-reveal.js).
Support was added for Asciidoctor `docinfo` and `sectnums` attributes, `kbd` macro and callout styles were fixed.

See the *upgrade considerations* section for the list of potentially breaking changes.

### Upgrade considerations

  * Due to an upstream change in reveal.js 3.8.0, this back-end no longer supports earlier reveal.js versions.
    We added a compatibility matrix with reveal.js at the end of the README.
    See [#301](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/301) for details.
  * Using the attribute `background-opacity` to alter the opacity of the title slide no longer works.
    When the opacity feature was introduced we forgot to align with the other title slide attributes.
    The feature was introduced in 3.0.0 and the bug stayed in 3.1.0.
    Starting with 4.0.0 use `title-slide-background-opacity` instead.
    See issue [#323](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/323) for details.
  * The new _Columns layout_ feature required a new `<div>` that wraps all slide content (everything except the slide title).
    This might impact custom CSS with strict child relationships.
    See issue [#326](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/326) and PR [#332](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/332) for details.
  * We bundle Highlight.js instead of relying on reveal.js.
    We reduced the core set of supported languages and added the `highlightjs-languages` attribute to add specific languages on demand.
    Depending on what type of code you were highlighting, you might need to add your language using that attribute.
    See [#320](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/320) for details.
  * Our support of AsciiDoc `docinfo` attribute changed.
    We were previously injecting `docinfo-header.html` somewhere in the HTML `<head>`.
    Now, `docinfo-revealjs.html` goes last into the HTML `<head>`, `docinfo-header-revealjs.html` goes right before the first slide `<section>` and `docinfo-footer-revealjs.html` goes right after the last slide `<section>`.
    The new documentation is available [here](https://github.com/asciidoctor/asciidoctor-reveal.js#supplemental-content-with-docinfo)
    and the related tickets are [#198](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/198)
    and [#324](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/324).
  * Default highlight.js theme is monokai. This follows a reveal.js change.

### Enhancements

  * New _Columns layout_ feature which provides easy to use roles to create multiple columns in slides.
    See the https://github.com/asciidoctor/asciidoctor-reveal.js#columns-layout[feature's documentation] for usage details.
    See issue [#326](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/326) and PRs [#332](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/332), [#340](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/340) for details.
  * Built-in slim templates can now be overridden with `--template-dir` or `-T` when using the Ruby command-line interface ([#177](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/177), [#318](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/318), [#349](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/349))
  * Highlight.js is now bundled by us instead of reveal.js.
    You can add other languages not supported in the core set by using the `highlightjs-languages` attribute.
    It can also be loaded locally or from a CDN of your choice.
    See issues [#21](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/21), [#319](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/319) and [#320](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/320) for details.
  * We now support the Java / JVM ecosystem.
    This packaging happens in a separate project: https://github.com/asciidoctor/asciidoctorj-reveal.js[AsciidoctorJ reveal.js].
    See issue [#217](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/271) and PR [#337](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/337) for details.
  * Many new examples demonstrating various features
  * Documentation improvements ([#322](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/322))
  * Refactoring ([#327](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/327), [#330](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/330), [#333](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/333))

### Compliance

  * New reveal.js 3.8.0 and 3.9.0 features supported ([#301](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/301))
  ** Line numbers on source code blocks using Asciidoctor's `linenums` attribute
  ** Specific lines and step-by-step code highlights using Asciidoctor's `highlight` attribute
  ** reveal.js `data-preview` on links and images with link can be activated by using the `preview` and `link_preview` Asciidoctor attributes respectively
  ** New configuration options: `hash`, `navigationMode`, `shuffle`, `preloadIframes`, `totalTime`, `minimumTimePerSlide`, `hideInactiveCursor`, `hideCursorTime`, `previewLinks` (`data-preview-link`) and `mobileViewDistance` ([#301](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/301))
  * Added support for the `sectnums` AsciiDoc attribute ([#185](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/185), [#317](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/317))
  * Aligned our `docinfo` support to Asciidoctor Bespoke ([#198](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/198), [#324](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/324))
  * Support the `highlightjs-languages` attribute from Asciidocotor ([#319](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/319), [#320](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/320))
  * `background-opacity` title slide attribute renamed to `title-slide-background-opacity` ([#323](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/323), [#325](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/325))
  * Added support for the `kdb` macro to represent keyboard shortcuts ([#276](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/276), [#329](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/329))
  * Cosmetic improvements to callout lists ([#335](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/335))

### Bug Fixes

  * Line height CSS fix with code listing with line numbers ([#331](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/331), [#334](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/334))
  * Interactive debugging works again ([#322](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/322))
  * Fixed _Uncaught ReferenceError: require is not defined_ by dropping outdated documentation ([#344](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/344))

### Release meta

* Released on: 2020-02-18
* Released by: Olivier Bilodeau
* Release drink: [Lime Flavored Sparkling Water](https://defi.leclub28.com/en/p/47E2C422178348F)

[git tag](https://github.com/asciidoctor/asciidoctor-reveal.js/releases/tag/v4.0.0) |
[full diff](https://github.com/asciidoctor/asciidoctor-reveal.js/compare/v3.1.0...v4.0.0) |
[milestone](https://github.com/asciidoctor/asciidoctor-reveal.js/milestone/8)

### Credits

Thanks to the following people who contributed to this release:

Guillaume Grossetie, Thomas and Olivier Bilodeau


## 3.1.0 (2020-01-18)

Fixed a regression with Font-Awesome brand icons, added a JavaScript CLI and standalone executables for Windows, Linux and macOS.

### Enhancements

  * We now provide native standalone executables for Windows, Linux and macOS using a Node to binary packager ([#259](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/259), [#308](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/308))
  * JavaScript stack now provides a CLI usable with `npx asciidoctor-revealjs` ([#308](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/308))
  * Updated to Font-Awesome 5.12.0 ([#305](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/305))
  * Ruby command line interface now shows Asciidoctor reveal.js version in addition to Asciidoctor version ([#313](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/313))
  * Updated dependencies: rake
  * Better tests ([#310](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/310), [#311](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/311))

### Bug Fixes

  * Added compatibility shim to Font Awesome 5 to fix brand icons rendering and more ([#304](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/304), [#305](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/305))

### Release meta

* Released on: 2020-01-18
* Released by: Olivier Bilodeau
* Release beer: Lupulus, Microbrasserie Charlevoix

[git tag](https://github.com/asciidoctor/asciidoctor-reveal.js/releases/tag/v3.1.0) |
[full diff](https://github.com/asciidoctor/asciidoctor-reveal.js/compare/v3.0.0...v3.1.0) |
[milestone](https://github.com/asciidoctor/asciidoctor-reveal.js/milestone/9)

### Credits

Thanks to the following people who contributed to this release:

Guillaume Grossetie and Olivier Bilodeau


## 3.0.0 (2020-01-07)

An API breaking release for Asciidoctor.js users that brings a bright future of long term stability.
New Reveal.js features supported: background opacity, background positions, and PDF export.
AsciiDoc table options now supported.
A big FontAwesome update.
Many other little improvements and polish.

Special heads-up: we are already planning for another major release since Reveal.js 3.8 support will be considered a breaking change.
They changed how it is loaded and requires a template change incompatible with Reveal.js 3.1-3.7.

### Upgrade considerations

  * Node.js packaging changes!
    With the arrival of Asciidoctor.js 2.0.0 you can now use a command line interface (CLI) just like with Asciidoctor Ruby:

        $(npm bin)/asciidoctor -r @asciidoctor/reveal.js -b revealjs presentation.adoc

    If you want to keep generating your reveal.js presentations using the Node.js API,
    you need to change the following code.
    Instead of:

      ```js
       var asciidoctorRevealjs = require('asciidoctor-reveal.js');
       asciidoctorRevealjs.register()
       ```

    Use:

       ```js
       var asciidoctor = require('@asciidoctor/core')()
       var asciidoctorRevealjs = require('@asciidoctor/reveal.js')
       asciidoctorRevealjs.register()
       ```

  * Node.js package name changed from `asciidoctor-reveal.js` to `@asciidoctor/reveal.js` (
    [#252](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/252),
    [#291](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/291))
  * Custom CSS might require adjustments.
    Source and listing block encapsulation changed due to our migration to Asciidoctor 2.0.0 Syntax Highlighter API.
    See [#287](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/287).
  * Upgraded to Font-Awesome 5.8.2 from 4.3.0 which contains some backward incompatible changes ([#268](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/268))
  * Asciidoctor reveal.js now requires Asciidoctor 2.0.0+ or Asciidoctor.js 2.0.0+ ([#290](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/290))
  * Dropped support for end-of-life Ruby version 2.1 and 2.2 ([#247](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/247))

### Compliance

  * Added support for table frame, grid, header and alignment options ([#29](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/29), [#42](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/42), [#56](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/56), [#288](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/288))
  * Source code callout style aligned with Asciidoctor's ([#293](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/293), [#300](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/300))
  * Added support for Reveal.js data-background-opacity ([#269](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/269))
  * Added support for Reveal.js data-background-position ([#273](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/273), [#274](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/274))
  * Updated the process to include the generated converter in releases ([#265](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/265), [#302](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/302))

### Enhancements
  * Support for Asciidoctor.js 2.0.0+ which brings a command line interface ([#254](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/254))
  * Process updates, narrower install version range and compatibility matrix regarding Asciidoctor.js ([#187](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/187), [#303](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/303))
  * Migrated to Asciidoctor 2.0.0 new [Syntax Highlighter API](https://github.com/asciidoctor/asciidoctor/releases/tag/v2.0.0) ([#261](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/261), [#287](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/287))
  * Added support for Reveal.js PDF export options ([#277](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/277))
  * Upgraded to Font-Awesome 5.8.2 ([#268](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/268))
  * We now accept `reveal.js` as converter/backend name in addition to `revealjs` ([#253](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/253), [#297](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/297))
  * Babel integration example API updated to use Asciidoctor reveal.js current API ([#285](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/285), [#298](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/298))
  * Node.js package clean-ups ([#279](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/279), [#281](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/281), [#282](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/282))
  * Upgrade Opal to use a compatible version with Asciidoctor.js 2.0.3 ([#289](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/289))
  * Documentation improvements ([#292](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/292), [#302](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/302))
  * Improvements to tests ([#294](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/294))

### Bug fixes
  * Babel integration example updated for security ([#285](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/285))

### Infrastructure
  * Updated Travis' JRuby to fix issues with bundler ([#295](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/295))

### Release meta

* Released on: 2020-01-07
* Released by: Olivier Bilodeau
* Release beer: Porter Baltique Édition Spéciale 2019, Les Trois Mousquetaires

[git tag](https://github.com/asciidoctor/asciidoctor-reveal.js/releases/tag/v3.0.0) |
[full diff](https://github.com/asciidoctor/asciidoctor-reveal.js/compare/v2.0.1...v3.0.0) |
[milestone](https://github.com/asciidoctor/asciidoctor-reveal.js/milestone/7)

### Credits

Thanks to the following people who contributed to this release:

Benjamin Schmid, Daniel Mulholland, Eiji Onchi, Gérald Quintana, Guillaume Grossetie and Olivier Bilodeau


## 2.0.1 (2019-12-04)

### Important Bug Fix

  * Fixed an issue that caused all `reveal.js` options in CamelCase to use the default value instead of one specified as an AsciiDoc attribute ([#263](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/263), [#267](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/267))

### Compliance

  * Dropped support for verse table cells ([#246](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/246)).
    Asciidoctor 2.0 dropped it, we followed.

### Enhancements

  * Documentation improvements (
    [#264](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/264),
    [#278](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/278),
    [#280](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/280))

### Bug Fixes

  * yarn.lock updates for security ([#283](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/283))

### Release meta

* Released on: 2019-12-04
* Released by: Olivier Bilodeau
* Release whisky: Lot No. 40 Single Copper Pot Still Rye Whisky

[git tag](https://github.com/asciidoctor/asciidoctor-reveal.js/releases/tag/v2.0.1) |
[full diff](https://github.com/asciidoctor/asciidoctor-reveal.js/compare/v2.0.0...v2.0.1)

### Credits

Thanks to the following people who contributed to this release:

Benjamin Schmid, Guillaume Grossetie, Olivier Bilodeau


## 2.0.0 (2019-02-28)

### Upgrade considerations

  * Node.js API change!
    If you generate your reveal.js presentations using the node/javascript toolchain, you need to change how the Asciidoctor reveal.js back-end is registered to Asciidoctor.js.
    Instead of `require('asciidoctor-reveal.js')` you need to do:

       ```js
       var asciidoctorRevealjs = require('asciidoctor-reveal.js');
       asciidoctorRevealjs.register()
       ```
    This change enables new use cases like embedding a presentation in a React web app.

  * Anchor links generated by Asciidoctor reveal.js will change from now on when revealjs_history is set to true (default is false).
    This is the consequence of upstream fixing a long standing issue (see [#1230](https://github.com/hakimel/reveal.js/pull/1230) and [#2037](https://github.com/hakimel/reveal.js/pull/2037)) and us removing a workaround (see [#232](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/232)).
    Explicit anchors are not affected.
  * Custom CSS might require adjustments.
    Source and listing block are less deeply nested into `div` blocks now.
    See [#195](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/195) and [#223](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/223).
  * The reveal.js `marked` and `markdown` plugins are disabled by default now.
    It is unlikely that they could have been used anyway.
    See [#204](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/204).
  * Dropped the ability to override the Reveal.JS theme and transitions dynamically with the URL query.
    Was not compatible with Reveal.JS 3.x series released 4 years ago.

### Enhancements

  * Easier speaker notes: a `.notes` role that apply to many AsciiDoc blocks (open, sidebar and admonition) ([#202](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/202))
  * Added a role `right` that would apply a `float: right` to any block where it would be assigned ([#197](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/197), [#213](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/213), [#215](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/215))
  * Allow the background color of slides to be set using CSS ([#16](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/16), [#220](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/220), [#226](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/226), [#229](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/229))
  * Reveal.js's fragmentInURL option now supported ([#206](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/206), [#214](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/214))
  * Documentation improvements ([#141](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/141), [#182](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/182), [#190](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/190), [#203](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/203), [#215](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/215), [#216](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/216), [#222](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/222))
  * Support for Asciidoctor.js 1.5.6 and build simplification ([#189](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/189), [#217](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/217))
  * Support to specify and use reveal.js plugins without modifying Asciidoctor reveal.js's source code ([#196](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/196), [#118](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/118), [#201](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/201), [#204](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/204))
  * Node / Javascript back-end is now loaded on-demand with the `register()` method.
    This allows embedding Asciidoctor reveal.js into React or any other modern Javascript environment.
    ([#205](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/205), [#218](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/218), [#219](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/219))
  * `revealjsdir` attribute is set to a more sensible default when running under Node.js ([#191](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/191), [#228](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/228))
  * Node / Javascript back-end updated to use Asciidoctor.js 1.5.9.
    This extension is built with Opal 0.11.99.dev (6703d8d) in order to be compatible.
    ([#227](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/227), [#240](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/240))

### Compliance

  * AsciiDoc source callout icons now work ([#54](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/54), [#168](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/168), [#224](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/224))
  * New reveal.js 3.7.0 features supported: `controlsTutorial`, `controlsLayout`, `controlsBackArrows`, new `slideNumber` formats, `showSlideNumber`, `autoSlideMethod`, `parallaxBackgroundHorizontal`, `parallaxBackgroundVertical` and `display` configuration parameters are now supported ([#212](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/212), [#239](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/239), [#208](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/208), [#242](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/242))
  * Asciidoctor 2.0 ready ([#245](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/245))

### Bug Fixes

  * Reveal.js' `stretch` class now works with listing blocks ([#195](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/195), [#223](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/223))
  * Auto-generated slide IDs with unallowed characters (for revealjs history) now work properly.
    Upstream reveal.js fixed a bug in 3.7.0 ([#2037](https://github.com/hakimel/reveal.js/pull/2037)) and we removed our broken workaround.
    ([#192](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/192), [#232](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/232))

### Infrastructure

  * Travis testing prepared for upcoming Asciidoctor 2.0 ([#216](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/216))
  * Travis testing for Ruby 2.6 ([#243](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/243))

### Release meta

* Released on: 2019-02-28
* Released by: Olivier Bilodeau
* Release beer: President's Choice Blonde Brew De-alcoholized Beer (Sober February Successfully Completed!)

[git tag](https://github.com/asciidoctor/asciidoctor-reveal.js/releases/tag/v2.0.0) |
[full diff](https://github.com/asciidoctor/asciidoctor-reveal.js/compare/v1.1.3...v2.0.0) |
[milestone](https://github.com/asciidoctor/asciidoctor-reveal.js/milestone/6)

### Credits

Thanks to the following people who contributed to this release:

a4z, Dan Allen, Guillaume Grossetie, Harald, Jakub Jirutka, Olivier Bilodeau, stevewillson, Vivien Didelot


## 1.1.3 (2018-01-31)

A repackage of 1.1.2 with a fix for Ruby 2.5 environments

### Bug fixes

  * Worked around a problem in ruby-beautify with the compiled Slim template under Ruby 2.5

### Release meta

* Released on: 2018-01-31
* Released by: Olivier Bilodeau
* Release coffee: Santropol Dark Espresso

[git tag](https://github.com/asciidoctor/asciidoctor-reveal.js/releases/tag/v1.1.3) |
[full diff](https://github.com/asciidoctor/asciidoctor-reveal.js/compare/v1.1.2...v1.1.3)

### Credits

Thanks to the following people who contributed to this release:

Jakub Jirutka, Olivier Bilodeau


## 1.1.2 (2018-01-30)

**NOTE:** No packaged version of this release were produced.

A bugfix release due to a problem rendering tables using the Javascript / Node.js toolchain.

###  Enhancements

  * Documentation improvements ([#181](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/181))

### Bug fixes

  * Fixed crash with presentations with a table used from Javascript/Node.js setup ([#178](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/178))

### Release meta

* Released on: 2018-01-30
* Released by: Olivier Bilodeau
* Release beer: A sad Belgian Moon in a Smoke Meat joint

[git tag](https://github.com/asciidoctor/asciidoctor-reveal.js/releases/tag/v1.1.2) |
[full diff](https://github.com/asciidoctor/asciidoctor-reveal.js/compare/v1.1.1...v1.1.2)

### Credits

Thanks to the following people who contributed to this release:

Guillaume Grossetie, Tobias Placht, Olivier Bilodeau


## 1.1.1 (2018-01-03)

An emergency bugfix release due to a problem in the Ruby Gem package

### Enhancements

  * Documentation improvements ([#163](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/163), [#165](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/165), [#169](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/169), [#173](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/173), [#175](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/175))

### Compliance

  * Code listing callouts now work properly ([#22](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/22), [#166](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/166), [#167](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/167))
  * More source code listing examples and tests ([#163](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/163), [#170](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/170))

### Bug fixes

  * The version 1.1.0 Ruby Gem was broken due to a packaging error ([#172](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/172))

### Release meta

* Released on: 2018-01-03
* Released by: Olivier Bilodeau
* Release beer: Croque-Mort Double IPA, À la fût

[git tag](https://github.com/asciidoctor/asciidoctor-reveal.js/releases/tag/v1.1.1) |
[full diff](https://github.com/asciidoctor/asciidoctor-reveal.js/compare/v1.1.0...v1.1.1) |
[milestone](https://github.com/asciidoctor/asciidoctor-reveal.js/milestone/5)

### Credits

Thanks to the following people who contributed to this release:

Dietrich Schulten, Olivier Bilodeau


## 1.1.0 (2017-12-25) - @obilodeau

### Enhancements

  * Support for Reveal.JS 3.5.0+ ([#146](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/146), [#151](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/151))
  * Support for Asciidoctor 1.5.6 ([#132](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/132), [#136](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/136), [#142](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/142))
  * Support for Asciidoctor.js 1.5.6-preview.4 ([#130](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/130), [#143](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/143), [#156](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/156))
  * Compiling slim templates to Ruby allows us to drop Jade templates for Asciidoctor.js users
    ([#63](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/63), [#131](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/131))
  * Documentation polish ([#153](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/153), [#158](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/158) and more)

### Compliance

  * Users of Asciidoctor (Ruby) and Asciidoctor.js (Javascript) now run the same set of templates meaning that we achieved feature parity between the two implementations
    ([#63](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/63), [#131](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/131))

### Bug fixes

  * Reveal.js https://github.com/hakimel/reveal.js/#configuration[history feature] now works.
    We are working around Reveal.js' section id character limits.
    ([#127](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/127), [#150](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/150), https://github.com/hakimel/reveal.js/issues/1346[hakimel/reveal.js#1346])

### Infrastructure

  * https://github.com/asciidoctor/asciidoctor-doctest[Asciidoctor-doctest] integration.
    This layer of automated testing should help prevent regressions and improve our development process.
    ([#92](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/92), [#116](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/116))
  * Travis-CI integration to automatically run doctests and examples AsciiDoc conversions
  * Travis-CI tests are triggered by changes done in Asciidoctor.
    We will detect upstream changes affecting us sooner.
  * Smoke tests for our Javascript / Node / Asciidoctor.js toolchain (integrated in Travis-CI also)
  * `npm run examples` will convert all examples using the Javascript / Node / Asciidoctor.js toolchain ([#149](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/149))
  * `rake examples:serve` will run a Web server from `examples/` so you can preview rendered examples ([#154](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/154))

### Release meta

[git tag](https://github.com/asciidoctor/asciidoctor-reveal.js/releases/tag/v1.1.0) |
[full diff](https://github.com/asciidoctor/asciidoctor-reveal.js/compare/v1.0.4...v1.1.0)

### Credits

Thanks to the following people who contributed to this release:

@jirutka, Dan Allen, Guillaume Grossetie, Jacob Aae Mikkelsen, Olivier Bilodeau, Rahul Somasunderam


## 1.0.4 (2017-09-27) - @obilodeau

### Bug fixes

  * Dependency problems leading to crashes when used from Asciidoctor.js ([#145](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/145))

### Release meta

[git tag](https://github.com/asciidoctor/asciidoctor-reveal.js/releases/tag/v1.0.4) |
[full diff](https://github.com/asciidoctor/asciidoctor-reveal.js/compare/v1.0.3...v1.0.4)

### Credits

Thanks to the following people who contributed to this release:

Olivier Bilodeau, Guillaume Grossetie


## 1.0.3 (2017-08-28) - @obilodeau

### Enhancements

  * Documentation improvements

### Compliance

  * Added `data-state: title` to the title slide ([#123](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/123))

### Bug fixes

  * Pinned Asciidoctor version requirement to 1.5.4 to avoid dealing with [#132](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/132) in the 1.0.x series
  * Fixed consistency issues with boolean values handling in revealjs settings ([#125](https://github.com/asciidoctor/asciidoctor-reveal.js/issues/125))

### Release meta

[git tag](https://github.com/asciidoctor/asciidoctor-reveal.js/releases/tag/v1.0.3) |
[full diff](https://github.com/asciidoctor/asciidoctor-reveal.js/compare/v1.0.2...v1.0.3)

### Credits

Thanks to the following people who contributed to this release:

Dan Allen, nipa, Olivier Bilodeau, Pi3r


## 1.0.2 (2016-12-22) - @obilodeau

### Enhancements

  * Ruby back-end is now compiled in Javascript with Opal (#115)
  * Documentation improvements

### Release meta

[issues resolved](https://github.com/asciidoctor/asciidoctor-reveal.js/issues?q=milestone%3A1.0.2) |
[git tag](https://github.com/asciidoctor/asciidoctor-reveal.js/releases/tag/v1.0.2) |
[full diff](https://github.com/asciidoctor/asciidoctor-reveal.js/compare/v1.0.1...v1.0.2)

### Credits

Thanks to the following people who contributed to this release:

Dan Allen, Guillaume Grossetie, Olivier Bilodeau


## 1.0.1 (2016-10-12) - @obilodeau

### Enhancements

  * Documentation: aligned release process for both npm and ruby gems packages
  * npm package in sync with ruby gem

### Release meta

Released by @obilodeau

[issues resolved](https://github.com/asciidoctor/asciidoctor-reveal.js/issues?q=milestone%3A1.0.1) |
[git tag](https://github.com/asciidoctor/asciidoctor-reveal.js/releases/tag/v1.0.1) |
[full diff](https://github.com/asciidoctor/asciidoctor-reveal.js/compare/v1.0.0...v1.0.1)

### Credits

Thanks to the following people who contributed to this release:

Olivier Bilodeau


## 1.0.0 (2016-10-06) - @obilodeau

Since this is the first ever "release" of asciidoctor-reveal.js (we used to do continuous improvements w/o releases in the past), this list focuses on the major enhancements introduced over the last few weeks.

### Enhancements

  * Initial release
  * Ruby package (#93)
  * Node package (#95)
  * `:customcss:` attribute for easy per-presentation CSS (#85)
  * Video support improvements (#81)
  * Reveal.js `data-state` support (#61)
  * Subtitle partioning (#70)
  * Background image rework (#52)
  * `:imagesdir:` properly enforced (#17, #67)

### Release meta

Released by @obilodeau

[issues resolved](https://github.com/asciidoctor/asciidoctor-reveal.js/issues?q=milestone%3A1.0.0) |
[git tag](https://github.com/asciidoctor/asciidoctor-reveal.js/releases/tag/v1.0.0)

### Credits

Thanks to the following people who contributed to this release:

Alexander Heusingfeld, Andrea Bedini, Antoine Sabot-Durand, Brian Street, Charles Moulliard, Dan Allen, Danny Hyun, Emmanuel Bernard, gtoast, Guillaume Grossetie, Jacob Aae Mikkelsen, Jakub Jirutka, Jozef Skrabo, Julien Grenier, Julien Kirch, kubamarchwicki, lifei, Nico Rikken, nipa, Olivier Bilodeau, Patrick van Dissel, phrix32, Rahman Usta, Robert Panzer, Rob Winch, Thomas and Wendell Smith
