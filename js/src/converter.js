// Native JavaScript port of lib/asciidoctor_revealjs/converter.rb
//
// Based on the Asciidoctor.js 4.0 converter API: this converter extends
// ConverterBase, implements `convert_<nodeName>` handlers and delegates any
// transform it does not implement to the built-in Html5Converter — mirroring
// the `@delegate_converter` pattern of the Ruby converter.
//
// Ruby → JavaScript notes:
//   - convert methods are async; `node.content()`, `node.imageUri()`,
//     `node.docinfo()` and `node.subMacros()` return Promises and are awaited.
//   - node.attr?  → node.hasAttribute() ; node.attr → node.getAttribute()
//   - node.option? → node.hasOption() ; node.has_role? → node.hasRole()
//   - Ruby symbol keys → plain string keys.

import { ConverterBase, Html5Converter, SafeMode } from 'asciidoctor'
import { extname } from 'node:path'
import { COMPATIBILITY } from './stylesheet.js'
import { script as revealJsScript } from './reveal-js-options.js'
import * as Footnotes from './footnotes.js'

// ── Constants ─────────────────────────────────────────────────────────────────

// Defaults (from the asciidoctor-html5s project).
const DEFAULT_TOCLEVELS = 2
const DEFAULT_SECTNUMLEVELS = 3

const STEM_EQNUMS_AMS = 'ams'
const STEM_EQNUMS_NONE = 'none'
const STEM_EQNUMS_VALID_VALUES = [STEM_EQNUMS_NONE, STEM_EQNUMS_AMS, 'all']

const MATHJAX_VERSION = '3.2.0'

// Asciidoctor core math delimiters (Asciidoctor::INLINE/BLOCK_MATH_DELIMITERS).
const INLINE_MATH_DELIMITERS = { asciimath: ['\\$', '\\$'], latexmath: ['\\(', '\\)'] }
const BLOCK_MATH_DELIMITERS = { asciimath: ['\\$', '\\$'], latexmath: ['\\[', '\\]'] }

// Two-or-more spaces in a title hint a manual line slice.
const SLICE_HINT_RX = /  +/

// ── Pure helpers ──────────────────────────────────────────────────────────────

// Ruby truthiness: only nil and false are falsy.
function rubyTruthy (val) {
  return val !== null && val !== undefined && val !== false
}

// Ruby nil_or_empty? for the values handled by attributes(): nil/'' and empty
// arrays are "empty"; numbers, true and non-empty strings are not.
function nilOrEmpty (val) {
  if (val === null || val === undefined) return true
  if (typeof val === 'string') return val.length === 0
  if (Array.isArray(val)) return val.length === 0
  return false
}

// Ruby String#chomp: remove a single trailing line separator.
function chomp (str) {
  return str.replace(/\r\n$|\n$|\r$/, '')
}

// Serializes a set of attributes into the string that goes inside an opening
// tag, e.g. { id: 'x', class: ['a', null, 'b'] } => ' id="x" class="a b"'.
// - null/false/empty values are omitted (so an absent id produces nothing);
// - true produces a boolean attribute (just the name, e.g. controls);
// - Array values are compacted and joined with a space.
function attributes (pairs) {
  let str = ''
  for (const key of Object.keys(pairs)) {
    let value = pairs[key]
    if (Array.isArray(value)) value = value.filter((item) => item !== null && item !== undefined).join(' ')
    if (!(rubyTruthy(value) && (value === true || !nilOrEmpty(value)))) continue
    str += value === true ? ` ${key}` : ` ${key}="${value}"`
  }
  return str
}

// Extracts the data- attributes from a node's attributes (renaming the special
// `step` attribute to `data-fragment-index`).
function dataAttrs (nodeAttributes) {
  const result = {}
  for (const key of Object.keys(nodeAttributes)) {
    const mapped = key === 'step' ? 'data-fragment-index' : key
    if (String(mapped).startsWith('data-')) result[mapped] = nodeAttributes[key]
  }
  return result
}

// Merges arbitrary data- attributes from a node's attributes into a set of
// already computed/known attributes, without letting the passthrough values
// clobber the known ones (e.g. data-background-color computed from the
// `background-color` shorthand attribute).
function mergeKnownDataAttrs (known, nodeAttributes) {
  const passthrough = dataAttrs(nodeAttributes)
  for (const key of Object.keys(known)) delete passthrough[key]
  return { ...known, ...passthrough }
}

// Whether the node should carry the reveal.js `fragment` class because it is
// part of a step. Variant used by most block elements.
function step (node) {
  return node.hasOption('step') || node.hasAttribute('step')
}

// Same as step() but also honours the `step` role. Used by list-like elements.
function stepOrRole (node) {
  return node.hasOption('step') || node.hasRole('step') || node.hasAttribute('step')
}

// Returns corrected section level.
function sectionLevel (sec) {
  return sec.getLevel() === 0 && sec.isSpecial() ? 1 : sec.getLevel()
}

// Returns the captioned section's title, optionally numbered.
function sectionTitle (sec) {
  const sectnumlevels = parseInt(sec.getDocument().getAttribute('sectnumlevels', DEFAULT_SECTNUMLEVELS), 10)
  if (sec.isNumbered() && !sec.getCaption() && sec.getLevel() <= sectnumlevels) {
    return [sec.sectnum(), sec.captionedTitle()].join(' ')
  }
  return sec.captionedTitle()
}

function sliceText (node, str, active = null) {
  if ((active || (active == null && node.hasOption('slice'))) && str.includes('  ')) {
    // NOTE: the Ruby source joins with the literal two-character string "\n".
    return str.split(SLICE_HINT_RX).map((line) => `<span class="line">${line}</span>`).join('\\n')
  }
  return str
}

// Ruby String#chomp('%'): remove a single trailing percent sign.
function chompPercent (str) {
  return String(str).replace(/%$/, '')
}

// Wrap the converted content in a <p> element when the content model is simple.
async function resolveContent (node) {
  return node.getContentModel() === 'simple' ? `<p>${await node.content()}</p>` : await node.content()
}

// Copied from asciidoctor html5 converter (private method).
function encodeAttributeValue (val) {
  return val.includes('"') ? val.replaceAll('"', '&quot;') : val
}

// If the AsciiDoc attribute doesn't exist, no HTML attribute is added.
// If it exists with a true value, the HTML attribute is enabled (boolean).
// If it exists with a false value, the HTML attribute is the string "false".
function boolDataAttr (node, val) {
  if (!node.hasAttribute(val)) return false
  const value = node.getAttribute(val)
  if (String(value).toLowerCase() === 'false' || value === '0') return 'false'
  return true
}

// Wrap inline text in a <span> when the node carries a role, an id or data- attributes.
function inlineTextContainer (node, content) {
  const da = dataAttrs(node.getAttributes())
  const fragment = node.hasOption('step') || node.hasAttribute('step') || node.getRoles().includes('step')
  const classes = [node.getRole(), fragment ? 'fragment' : null].filter((item) => item != null)
  if (node.getRoles().length > 0 || Object.keys(da).length > 0 || node.getId() != null) {
    return `<span${attributes({ id: node.getId(), class: classes, ...da })}>${content}</span>`
  }
  return content
}

// Copied from asciidoctor html5 converter (private method).
function appendLinkConstraintAttrs (node, attrs = []) {
  const rel = node.hasOption('nofollow') ? 'nofollow' : null
  const window = node.getAttributes().window
  if (window) {
    attrs.push(` target="${window}"`)
    if (window === '_blank' || node.hasOption('noopener')) attrs.push(rel ? ` rel="${rel} noopener"` : ' rel="noopener"')
  } else if (rel) {
    attrs.push(` rel="${rel}"`)
  }
  return attrs
}

// ── Converter ─────────────────────────────────────────────────────────────────

export default class RevealJsConverter extends ConverterBase {
  static create (backend = 'revealjs', opts = {}) {
    return new this(backend, opts)
  }

  constructor (backend, opts = {}) {
    super(backend, opts)
    this.initBackendTraits({
      basebackend: 'html',
      filetype: 'html',
      htmlsyntax: 'html',
      outfilesuffix: '.html',
      supportsTemplates: true
    })
    const delegateBackend = String(opts.delegate_backend || 'html5')
    this.delegateConverter = new Html5Converter(delegateBackend, opts)
  }

  convert (node, transform = null, opts = null) {
    const method = `convert_${transform ?? node.nodeName}`
    if (typeof this[method] === 'function') {
      return opts ? this[method](node, opts) : this[method](node)
    }
    return this.delegateConverter.convert(node, transform, opts)
  }

  async convert_document (node) {
    const slidesContent = await node.content()
    const slides = async () => {
      let buf = ''
      if (!node.isNoheader()) {
        const headerDocinfo = await node.docinfo('header', '-revealjs.html')
        if (headerDocinfo) buf += headerDocinfo
        if (node.hasHeader() && !node.isNotitle()) buf += await this.convert(node, 'title_slide')
      }
      buf += slidesContent ?? ''
      const footerDocinfo = await node.docinfo('footer', '-revealjs.html')
      if (footerDocinfo) buf += footerDocinfo
      return buf
    }

    const revealjsdir = node.getAttribute('revealjsdir', 'node_modules/reveal.js')
    let assetUriScheme = node.getAttribute('asset-uri-scheme', 'https')
    if (assetUriScheme !== '') assetUriScheme = `${assetUriScheme}:`
    const cdnBase = `${assetUriScheme}//cdnjs.cloudflare.com/ajax/libs`

    let buf = '<!DOCTYPE html><html'
    const lang = node.hasAttribute('nolang') ? null : node.getAttribute('lang', 'en')
    if (lang) buf += ` lang="${lang}"`
    buf += '><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, minimal-ui">'
    buf += `<title>${node.doctitle({ sanitize: true, use_fallback: true })}</title>`

    for (const key of ['description', 'keywords', 'author', 'copyright']) {
      if (node.hasAttribute(key)) buf += `<meta${attributes({ name: key, content: node.getAttribute(key) })}>`
    }
    if (node.hasAttribute('favicon')) {
      let iconHref = node.getAttribute('favicon')
      let iconType
      if (iconHref === '') {
        iconHref = 'favicon.ico'
        iconType = 'image/x-icon'
      } else {
        const iconExt = extname(iconHref)
        iconType = iconExt === '.ico' ? 'image/x-icon' : `image/${iconExt.slice(1)}`
      }
      buf += `<link rel="icon" type="${iconType}" href="${iconHref}">`
    }
    const linkcss = node.hasAttribute('linkcss')
    buf += `<link rel="stylesheet" href="${revealjsdir}/dist/reset.css"><link rel="stylesheet" href="${revealjsdir}/dist/reveal.css">`
    // Default theme required even when using custom theme
    buf += `<link${attributes({
      rel: 'stylesheet',
      href: node.getAttribute('revealjs_customtheme', `${revealjsdir}/dist/theme/${node.getAttribute('revealjs_theme', 'black')}.css`),
      id: 'theme'
    })}>`
    buf += "<!--This CSS is generated by the Asciidoctor reveal.js converter to further integrate AsciiDoc's existing semantic with reveal.js-->"
    buf += `<style type="text/css">${COMPATIBILITY}</style>`
    if (node.hasAttribute('icons', 'font')) {
      // iconfont-remote is implicitly set by Asciidoctor core.
      if (node.hasAttribute('iconfont-remote')) {
        const iconfontCdn = node.getAttribute('iconfont-cdn')
        if (iconfontCdn != null) {
          buf += `<link${attributes({ rel: 'stylesheet', href: iconfontCdn })}>`
        } else {
          const fontAwesomeVersion = node.getAttribute('font-awesome-version', '5.15.1')
          buf += `<link${attributes({ rel: 'stylesheet', href: `${cdnBase}/font-awesome/${fontAwesomeVersion}/css/all.min.css` })}>`
          buf += `<link${attributes({ rel: 'stylesheet', href: `${cdnBase}/font-awesome/${fontAwesomeVersion}/css/v4-shims.min.css` })}>`
        }
      } else {
        buf += `<link${attributes({
          rel: 'stylesheet',
          href: node.normalizeWebPath(`${node.getAttribute('iconfont-name', 'font-awesome')}.css`, node.getAttribute('stylesdir', ''), false)
        })}>`
      }
    }
    buf += this.generateStem(node, cdnBase) ?? ''
    const syntaxHl = node.syntaxHighlighter
    if (syntaxHl && syntaxHl.hasDocinfo('head')) {
      buf += syntaxHl.docinfo('head', node, { cdn_base_url: cdnBase, linkcss, self_closing_tag_slash: '/' }) ?? ''
    }
    if (node.hasAttribute('customcss')) {
      const customcss = node.getAttribute('customcss')
      buf += `<link${attributes({ rel: 'stylesheet', href: customcss === '' ? 'asciidoctor-revealjs.css' : customcss })}>`
    }
    const docinfoHead = await node.docinfo('head', '-revealjs.html')
    if (docinfoHead) buf += docinfoHead
    buf += '</head><body><div class="reveal"><div class="slides">'
    // Any section element inside of this container is displayed as a slide
    buf += await slides()
    buf += '</div></div>'
    buf += revealJsScript(node, revealjsdir)

    if (syntaxHl && syntaxHl.hasDocinfo('footer')) {
      buf += syntaxHl.docinfo('footer', node, { cdn_base_url: cdnBase, linkcss, self_closing_tag_slash: '/' }) ?? ''
    }
    const docinfoContent = await node.docinfo('footer', '.html')
    if (docinfoContent) buf += docinfoContent
    buf += '</body></html>'
    return buf
  }

  async convert_title_slide (node) {
    const bgImage = node.hasAttribute('title-slide-background-image') ? await node.imageUri(node.getAttribute('title-slide-background-image')) : null
    const bgVideo = node.hasAttribute('title-slide-background-video') ? node.mediaUri(node.getAttribute('title-slide-background-video')) : null
    const attrs = attributes(mergeKnownDataAttrs({
      class: ['title', node.getRole()],
      'data-state': 'title',
      'data-transition': node.getAttribute('title-slide-transition'),
      'data-transition-speed': node.getAttribute('title-slide-transition-speed'),
      'data-background': node.getAttribute('title-slide-background'),
      'data-background-size': node.getAttribute('title-slide-background-size'),
      'data-background-image': bgImage,
      'data-background-video': bgVideo,
      'data-background-video-loop': node.getAttribute('title-slide-background-video-loop'),
      'data-background-video-muted': node.getAttribute('title-slide-background-video-muted'),
      'data-background-opacity': node.getAttribute('title-slide-background-opacity'),
      'data-background-iframe': node.getAttribute('title-slide-background-iframe'),
      'data-background-color': node.getAttribute('title-slide-background-color'),
      'data-background-repeat': node.getAttribute('title-slide-background-repeat'),
      'data-background-position': node.getAttribute('title-slide-background-position'),
      'data-background-transition': node.getAttribute('title-slide-background-transition')
    }, node.getAttributes()))
    let buf = ''
    const titleObj = node.doctitle({ partition: true, use_fallback: true })
    if (titleObj.hasSubtitle()) {
      const headerSlice = node.getHeader().hasOption('slice')
      buf += `<h1>${sliceText(node, titleObj.title, headerSlice)}</h1><h2>${sliceText(node, titleObj.subtitle, headerSlice)}</h2>`
    } else {
      buf += `<h1>${node.getHeader().title}</h1>`
    }
    const preamble = node.getDocument().findBy({ context: 'preamble' })
    if (preamble && preamble.length > 0) {
      buf += `<div class="preamble">${await preamble[preamble.length - 1].content()}</div>`
    }
    buf += (await this.generateAuthors(node.getDocument())) ?? ''
    return `<section${attrs}>${buf}</section>`
  }

  async convert_section (node) {
    // OPTIONS PROCESSING
    // hide slides on %conceal, %notitle and named "!"
    const title = node.getTitle()
    const titleless = title === '!'
    const hideTitle = titleless || node.hasOption('notitle') || node.hasOption('conceal')

    const verticalSlides = node.findBy({ context: 'section' }, (section) => section.getLevel() === 2)

    // extracting block image attributes to find an image to use as a background_image attribute
    let dataBackgroundImage = null
    let dataBackgroundSize = null
    let dataBackgroundRepeat = null
    let dataBackgroundPosition = null
    let dataBackgroundTransition = null
    let dataBackgroundVideo = null
    let dataBackgroundColor = null

    // process the first image block in the current section that acts as a background
    const sectionImages = []
    for (const block of node.getBlocks()) {
      const ctx = block.getContext()
      if (ctx === 'image') {
        if (['background', 'canvas'].includes(block.getAttribute(1))) sectionImages.push(block)
      } else if (ctx === 'section') {
        // skip nested sections
      } else {
        sectionImages.push(...block.findBy({ context: 'image' }, (image) => ['background', 'canvas'].includes(image.getAttribute(1))))
      }
    }
    const bgImage = sectionImages[0]
    if (bgImage) {
      dataBackgroundImage = await bgImage.imageUri(bgImage.getAttribute('target'))
      dataBackgroundSize = bgImage.getAttribute('size')
      dataBackgroundRepeat = bgImage.getAttribute('repeat')
      dataBackgroundTransition = bgImage.getAttribute('transition')
      dataBackgroundPosition = bgImage.getAttribute('position')
    }

    // background-image section attribute overrides the image one
    if (node.hasAttribute('background-image')) dataBackgroundImage = await node.imageUri(node.getAttribute('background-image'))
    if (node.hasAttribute('background-video')) dataBackgroundVideo = node.mediaUri(node.getAttribute('background-video'))
    if (node.hasAttribute('background-color')) dataBackgroundColor = node.getAttribute('background-color')

    const parentSectionWithVerticalSlides = node.getLevel() === 1 && verticalSlides.length > 0

    const footnotes = () => {
      const slideFn = Footnotes.slideFootnotes(node)
      if (node.getDocument().hasFootnotes() && !node.getParent().hasAttribute('nofootnotes') && slideFn.length > 0) {
        return `<div class="footnotes">${slideFn.map((footnote) => `<div class="footnote">${footnote.index}. ${footnote.text}</div>`).join('')}</div>`
      }
      return ''
    }

    const section = async () => {
      const attrs = attributes(mergeKnownDataAttrs({
        id: titleless ? null : node.getId(),
        class: node.getRoles(),
        'data-background-gradient': node.getAttribute('background-gradient'),
        'data-transition': node.getAttribute('transition'),
        'data-transition-speed': node.getAttribute('transition-speed'),
        'data-background-color': dataBackgroundColor,
        'data-background-image': dataBackgroundImage,
        'data-background-size': dataBackgroundSize ?? node.getAttribute('background-size'),
        'data-background-repeat': dataBackgroundRepeat ?? node.getAttribute('background-repeat'),
        'data-background-transition': dataBackgroundTransition ?? node.getAttribute('background-transition'),
        'data-background-position': dataBackgroundPosition ?? node.getAttribute('background-position'),
        'data-background-iframe': node.getAttribute('background-iframe'),
        'data-background-video': dataBackgroundVideo,
        'data-background-video-loop': node.hasAttribute('background-video-loop') || node.hasOption('loop'),
        'data-background-video-muted': node.hasAttribute('background-video-muted') || node.hasOption('muted'),
        'data-background-opacity': node.getAttribute('background-opacity'),
        'data-autoslide': node.getAttribute('autoslide'),
        'data-state': node.getAttribute('state'),
        'data-auto-animate': node.hasAttribute('auto-animate') || node.hasOption('auto-animate'),
        'data-auto-animate-easing': node.getAttribute('auto-animate-easing') || node.hasOption('auto-animate-easing'),
        'data-auto-animate-unmatched': node.getAttribute('auto-animate-unmatched') || node.hasOption('auto-animate-unmatched'),
        'data-auto-animate-duration': node.getAttribute('auto-animate-duration') || node.hasOption('auto-animate-duration'),
        'data-auto-animate-id': node.getAttribute('auto-animate-id'),
        'data-auto-animate-restart': node.hasAttribute('auto-animate-restart') || node.hasOption('auto-animate-restart')
      }, node.getAttributes()))
      let inner = ''
      if (!hideTitle) inner += `<h2>${sectionTitle(node)}</h2>`
      if (parentSectionWithVerticalSlides) {
        const blocks = node.getBlocks().filter((block) => !verticalSlides.includes(block))
        if (blocks.length > 0) {
          // Convert sequentially: the per-slide footnote state is shared module-level
          // state and must be mutated in document order (Ruby is fully synchronous).
          let converted = ''
          for (const block of blocks) converted += await block.convert()
          inner += `<div class="slide-content">${converted}</div>`
        }
      } else {
        const content = chomp(await node.content())
        if (content !== '') inner += `<div class="slide-content">${content}</div>`
      }
      inner += footnotes()
      return `<section${attrs}>${inner}</section>`
    }

    // RENDERING
    if (parentSectionWithVerticalSlides) {
      // render parent section of vertical slides set (sequentially: see note above)
      const parentSection = await section()
      let vs = ''
      for (const slide of verticalSlides) vs += await slide.convert()
      return `<section>${parentSection}${vs}</section>`
    } else if (node.getLevel() >= 3) {
      // dynamic tags which map <hX> with level
      return `<h${node.getLevel()}>${title}</h${node.getLevel()}>${chomp(await node.content())}`
    } else {
      // render standalone slides (or vertical slide subsection)
      return section()
    }
  }

  async convert_paragraph (node) {
    const attrs = attributes({ id: node.getId(), class: ['paragraph', node.getRole(), step(node) ? 'fragment' : null], ...dataAttrs(node.getAttributes()) })
    let buf = ''
    if (node.hasTitle()) buf += `<div class="title">${node.getTitle()}</div>`
    buf += node.hasRole('small') ? `<small>${await node.content()}</small>` : `<p>${await node.content()}</p>`
    return `<div${attrs}>${buf}</div>`
  }

  convert_preamble () {
    // preamble is shown on the title slide which is rendered by the document method
    return ''
  }

  async convert_olist (node) {
    const attrs = attributes({ id: node.getId(), class: ['olist', node.getStyle(), node.getRole()], ...dataAttrs(node.getAttributes()) })
    let buf = ''
    if (node.hasTitle()) buf += `<div class="title">${node.getTitle()}</div>`
    let inner = ''
    for (const item of node.getItems()) {
      let li = `<p>${item.getText()}</p>`
      if (item.hasBlocks()) li += await item.content()
      inner += `<li${attributes({ class: stepOrRole(node) ? 'fragment' : null })}>${li}</li>`
    }
    buf += `<ol${attributes({ class: node.getStyle(), start: node.getAttribute('start'), type: node.listMarkerKeyword() })}>${inner}</ol>`
    return `<div${attrs}>${buf}</div>`
  }

  async convert_ulist (node) {
    let checklist = null
    let markerChecked
    let markerUnchecked
    if (node.hasOption('checklist')) {
      checklist = 'checklist'
      if (node.hasOption('interactive')) {
        markerChecked = '<input type="checkbox" data-item-complete="1" checked>'
        markerUnchecked = '<input type="checkbox" data-item-complete="0">'
      } else if (node.getDocument().hasAttribute('icons', 'font')) {
        markerChecked = '<i class="fa fa-check-square-o"></i>'
        markerUnchecked = '<i class="fa fa-square-o"></i>'
      } else {
        // could use &#9745 (checked ballot) and &#9744 (ballot) w/o font instead
        markerChecked = '<input type="checkbox" data-item-complete="1" checked disabled>'
        markerUnchecked = '<input type="checkbox" data-item-complete="0" disabled>'
      }
    }
    const attrs = attributes({ id: node.getId(), class: ['ulist', checklist, node.getStyle(), node.getRole()], ...dataAttrs(node.getAttributes()) })
    let buf = ''
    if (node.hasTitle()) buf += `<div class="title">${node.getTitle()}</div>`
    let inner = ''
    for (const item of node.getItems()) {
      let li = '<p>'
      if (checklist && item.hasAttribute('checkbox')) {
        li += `${item.hasAttribute('checked') ? markerChecked : markerUnchecked}${item.getText()}`
      } else {
        li += item.getText() ?? ''
      }
      li += '</p>'
      if (item.hasBlocks()) li += await item.content()
      inner += `<li${attributes({ class: stepOrRole(node) ? 'fragment' : null })}>${li}</li>`
    }
    buf += `<ul${attributes({ class: checklist || node.getStyle() })}>${inner}</ul>`
    return `<div${attrs}>${buf}</div>`
  }

  async convert_admonition (node) {
    if (node.hasRole('aside') || node.hasRole('speaker') || node.hasRole('notes')) {
      return `<aside class="notes">${await resolveContent(node)}</aside>`
    }
    const attrs = attributes({ id: node.getId(), class: ['admonitionblock', node.getAttribute('name'), node.getRole(), step(node) ? 'fragment' : null], ...dataAttrs(node.getAttributes()) })
    let icon
    if (node.getDocument().hasAttribute('icons', 'font')) {
      const iconMapping = { caution: 'fire', important: 'exclamation-circle', note: 'info-circle', tip: 'lightbulb-o', warning: 'warning' }
      icon = `<i${attributes({ class: `fa fa-${iconMapping[node.getAttribute('name')]}`, title: node.getAttribute('textlabel') })}></i>`
    } else if (node.getDocument().hasAttribute('icons')) {
      icon = `<img${attributes({ src: await node.iconUri(node.getAttribute('name')), alt: node.getCaption() })}>`
    } else {
      icon = `<div class="title">${node.getAttribute('textlabel') || node.getCaption()}</div>`
    }
    let cell = ''
    if (node.hasTitle()) cell += `<div class="title">${node.getTitle()}</div>`
    cell += (await node.content()) ?? ''
    return `<div${attrs}><table><tr><td class="icon">${icon}</td><td class="content">${cell}</td></tr></table></div>`
  }

  async convert_audio (node) {
    const attrs = attributes({ id: node.getId(), class: ['audioblock', node.getStyle(), node.getRole()], ...dataAttrs(node.getAttributes()) })
    let buf = ''
    if (node.hasTitle()) buf += `<div class="title">${node.getCaptionedTitle()}</div>`
    buf += '<div class="content">'
    buf += `<audio${attributes({ src: node.mediaUri(node.getAttribute('target')), autoplay: node.hasOption('autoplay'), controls: !node.hasOption('nocontrols'), loop: node.hasOption('loop') })}>Your browser does not support the audio tag.</audio>`
    buf += '</div>'
    return `<div${attrs}>${buf}</div>`
  }

  async convert_colist (node) {
    const attrs = attributes({ id: node.getId(), class: ['colist', node.getStyle(), node.getRole()], ...dataAttrs(node.getAttributes()) })
    let buf = ''
    if (node.hasTitle()) buf += `<div class="title">${node.getTitle()}</div>`
    if (node.getDocument().hasAttribute('icons')) {
      const fontIcons = node.getDocument().hasAttribute('icons', 'font')
      buf += '<table>'
      const items = node.getItems()
      for (let i = 0; i < items.length; i++) {
        const num = i + 1
        let cell = '<td>'
        if (fontIcons) {
          cell += `<i${attributes({ class: 'conum', 'data-value': num })}></i>`
          cell += `<b>${num}</b>`
        } else {
          cell += `<img${attributes({ src: await node.iconUri(`callouts/${num}`), alt: num })}>`
        }
        cell += `</td><td>${items[i].getText()}</td>`
        buf += `<tr${attributes({ class: stepOrRole(node) ? 'fragment' : null })}>${cell}</tr>`
      }
      buf += '</table>'
    } else {
      buf += '<ol>'
      for (const item of node.getItems()) {
        buf += `<li${attributes({ class: stepOrRole(node) ? 'fragment' : null })}><p>${item.getText()}</p></li>`
      }
      buf += '</ol>'
    }
    return `<div${attrs}>${buf}</div>`
  }

  async convert_dlist (node) {
    switch (node.getStyle()) {
      case 'qanda': {
        const attrs = attributes({ id: node.getId(), class: ['qlist', node.getStyle(), node.getRole()], ...dataAttrs(node.getAttributes()) })
        let buf = ''
        if (node.hasTitle()) buf += `<div class="title">${node.getTitle()}</div>`
        buf += '<ol>'
        for (const [questions, answer] of node.getItems()) {
          buf += '<li>'
          for (const question of questions) buf += `<p><em>${question.getText()}</em></p>`
          if (answer != null) {
            if (answer.hasText()) buf += `<p>${answer.getText()}</p>`
            if (answer.hasBlocks()) buf += await answer.content()
          }
          buf += '</li>'
        }
        buf += '</ol>'
        return `<div${attrs}>${buf}</div>`
      }
      case 'horizontal': {
        const attrs = attributes({ id: node.getId(), class: ['hdlist', node.getRole()], ...dataAttrs(node.getAttributes()) })
        let buf = ''
        if (node.hasTitle()) buf += `<div class="title">${node.getTitle()}</div>`
        buf += '<table>'
        if (node.hasAttribute('labelwidth') || node.hasAttribute('itemwidth')) {
          buf += '<colgroup>'
          buf += `<col${attributes({ style: node.hasAttribute('labelwidth') ? `width:${chompPercent(node.getAttribute('labelwidth'))}%;` : null })}>`
          buf += `<col${attributes({ style: node.hasAttribute('itemwidth') ? `width:${chompPercent(node.getAttribute('itemwidth'))}%;` : null })}>`
          buf += '</colgroup>'
        }
        for (const [terms, dd] of node.getItems()) {
          buf += '<tr>'
          let cell = ''
          const lastTerm = terms[terms.length - 1]
          for (const dt of terms) {
            cell += dt.getText() ?? ''
            if (dt !== lastTerm) cell += '<br>'
          }
          buf += `<td${attributes({ class: ['hdlist1', node.hasOption('strong') ? 'strong' : null] })}>${cell}</td>`
          buf += '<td class="hdlist2">'
          if (dd != null) {
            if (dd.hasText()) buf += `<p>${dd.getText()}</p>`
            if (dd.hasBlocks()) buf += await dd.content()
          }
          buf += '</td></tr>'
        }
        buf += '</table>'
        return `<div${attrs}>${buf}</div>`
      }
      default: {
        const attrs = attributes({ id: node.getId(), class: ['dlist', node.getStyle(), node.getRole()], ...dataAttrs(node.getAttributes()) })
        let buf = ''
        if (node.hasTitle()) buf += `<div class="title">${node.getTitle()}</div>`
        buf += '<dl>'
        for (const [terms, dd] of node.getItems()) {
          for (const dt of terms) buf += `<dt${attributes({ class: node.getStyle() ? null : 'hdlist1' })}>${dt.getText()}</dt>`
          if (dd == null) continue
          buf += '<dd>'
          if (dd.hasText()) buf += `<p>${dd.getText()}</p>`
          if (dd.hasBlocks()) buf += await dd.content()
          buf += '</dd>'
        }
        buf += '</dl>'
        return `<div${attrs}>${buf}</div>`
      }
    }
  }

  async convert_embedded (node) {
    let buf = ''
    if (!node.isNotitle() && node.hasHeader()) buf += `<h1${attributes({ id: node.getId() })}>${node.getHeader().title}</h1>`
    buf += (await node.content()) ?? ''
    if (node.hasFootnotes() && !node.hasAttribute('nofootnotes')) {
      buf += '<div id="footnotes"><hr>'
      for (const fn of node.getFootnotes()) {
        buf += `<div class="footnote" id="_footnote_${fn.getIndex()}"><a href="#_footnoteref_${fn.getIndex()}">${fn.getIndex()}</a>. ${fn.getText()}</div>`
      }
      buf += '</div>'
    }
    return buf
  }

  async convert_example (node) {
    const attrs = attributes({ id: node.getId(), class: ['exampleblock', node.getRole(), step(node) ? 'fragment' : null], ...dataAttrs(node.getAttributes()) })
    let buf = ''
    if (node.hasTitle()) buf += `<div class="title">${node.getCaptionedTitle()}</div>`
    buf += `<div class="content">${await node.content()}</div>`
    return `<div${attrs}>${buf}</div>`
  }

  convert_floating_title (node) {
    const level = node.getLevel() + 1
    return `<h${level}${attributes({ id: node.getId(), class: [node.getStyle(), node.getRole()] })}>${node.getTitle()}</h${level}>`
  }

  async convert_image (node) {
    if (['background', 'canvas'].includes(node.getAttribute(1))) return ''

    const inlineStyle = [node.hasAttribute('align') ? `text-align: ${node.getAttribute('align')}` : null, node.hasAttribute('float') ? `float: ${node.getAttribute('float')}` : null].filter((item) => item != null).join('; ')
    const attrs = attributes({ id: node.getId(), class: ['imageblock', node.getRole(), step(node) ? 'fragment' : null], style: inlineStyle, ...dataAttrs(node.getAttributes()) })
    let buf = `<div${attrs}>${await this.imageContent(node)}</div>`
    if (node.hasTitle()) buf += `<div class="title">${node.getCaptionedTitle()}</div>`
    return buf
  }

  convert_inline_anchor (node) {
    switch (node.getType()) {
      case 'xref': {
        const refid = node.getAttribute('refid') || node.getTarget()
        const attrs = attributes({ href: node.getTarget(), class: [node.getRole(), step(node) ? 'fragment' : null], ...dataAttrs(node.getAttributes()) })
        const ids = node.getDocument().references.ids
        const text = (node.getText() || (refid in ids ? ids[refid] : `[${refid}]`)).replace(/\n+/g, ' ')
        return `<a${attrs}>${text}</a>`
      }
      case 'ref':
        return `<a${attributes({ id: node.getTarget(), ...dataAttrs(node.getAttributes()) })}></a>`
      case 'bibref':
        return `<a${attributes({ id: node.getTarget(), ...dataAttrs(node.getAttributes()) })}></a>[${node.getTarget() ?? ''}]`
      default: {
        const attrs = attributes({ href: node.getTarget(), class: [node.getRole(), step(node) ? 'fragment' : null], target: node.getAttribute('window'), 'data-preview-link': boolDataAttr(node, 'preview'), ...dataAttrs(node.getAttributes()) })
        return `<a${attrs}>${node.getText()}</a>`
      }
    }
  }

  convert_inline_break (node) {
    return `${node.getText()}<br>`
  }

  convert_inline_button (node) {
    return `<b${attributes({ class: ['button'], ...dataAttrs(node.getAttributes()) })}>${node.getText()}</b>`
  }

  async convert_inline_callout (node) {
    if (node.getDocument().hasAttribute('icons', 'font')) {
      return `<i${attributes({ class: 'conum', 'data-value': node.getText() })}></i><b>(${node.getText()})</b>`
    } else if (node.getDocument().hasAttribute('icons')) {
      return `<img${attributes({ src: await node.iconUri(`callouts/${node.getText()}`), alt: node.getText() })}>`
    }
    return `<b>(${node.getText()})</b>`
  }

  convert_inline_footnote (node) {
    const footnote = Footnotes.slideFootnote(node)
    const index = footnote.getAttribute('index')
    const id = footnote.getId()
    if (node.getType() === 'xref') {
      return `<sup${attributes({ class: ['footnoteref'], ...dataAttrs(footnote.getAttributes()) })}>[<span class="footnote" title="View footnote.">${index}</span>]</sup>`
    }
    return `<sup${attributes({ id: id ? `_footnote_${id}` : null, class: ['footnote'], ...dataAttrs(footnote.getAttributes()) })}>[<span class="footnote" title="View footnote.">${index}</span>]</sup>`
  }

  async convert_inline_image (node) {
    const attrs = attributes({ class: [node.getType(), node.getRole(), step(node) ? 'fragment' : null], style: node.hasAttribute('float') ? `float: ${node.getAttribute('float')}` : null, ...dataAttrs(node.getAttributes()) })
    return `<span${attrs}>${await this.inlineImageContent(node)}</span>`
  }

  convert_inline_indexterm (node) {
    return node.getType() === 'visible' ? node.getText() : ''
  }

  convert_inline_kbd (node) {
    const keys = node.getAttribute('keys')
    if (keys.length === 1) {
      return `<kbd${attributes(dataAttrs(node.getAttributes()))}>${keys[0]}</kbd>`
    }
    let buf = ''
    keys.forEach((key, idx) => {
      if (idx !== 0) buf += '+'
      buf += `<kbd>${key}</kbd>`
    })
    return `<span${attributes({ class: ['keyseq'], ...dataAttrs(node.getAttributes()) })}>${buf}</span>`
  }

  convert_inline_menu (node) {
    const menu = node.getAttribute('menu')
    const menuitem = node.getAttribute('menuitem')
    const submenus = node.getAttribute('submenus')
    if (submenus && submenus.length > 0) {
      const content = `<span class="menu">${menu}</span>&#160;&#9656;&#32;` +
        submenus.map((submenu) => `<span class="submenu">${submenu}</span>&#160;&#9656;&#32;`).join('') +
        `<span class="menuitem">${menuitem}</span>`
      return `<span${attributes({ class: ['menuseq'], ...dataAttrs(node.getAttributes()) })}>${content}</span>`
    } else if (menuitem != null) {
      return `<span${attributes({ class: ['menuseq'], ...dataAttrs(node.getAttributes()) })}><span class="menu">${menu}</span>&#160;&#9656;&#32;<span class="menuitem">${menuitem}</span></span>`
    }
    return `<span${attributes({ class: ['menu'], ...dataAttrs(node.getAttributes()) })}>${menu}</span>`
  }

  convert_inline_quoted (node) {
    const quoteTags = { emphasis: 'em', strong: 'strong', monospaced: 'code', superscript: 'sup', subscript: 'sub' }
    const quoteTag = quoteTags[node.getType()]
    if (quoteTag) {
      return `<${quoteTag}${attributes({ id: node.getId(), class: [node.getRole(), step(node) ? 'fragment' : null], ...dataAttrs(node.getAttributes()) })}>${node.getText()}</${quoteTag}>`
    }
    switch (node.getType()) {
      case 'double': return inlineTextContainer(node, `&#8220;${node.getText()}&#8221;`)
      case 'single': return inlineTextContainer(node, `&#8216;${node.getText()}&#8217;`)
      case 'asciimath':
      case 'latexmath': {
        const [open, close] = INLINE_MATH_DELIMITERS[node.getType()]
        return inlineTextContainer(node, `${open}${node.getText()}${close}`)
      }
      default: return inlineTextContainer(node, node.getText())
    }
  }

  async convert_listing (node) {
    const nowrap = node.hasOption('nowrap') || !node.getDocument().hasAttribute('prewrap')
    let syntaxHl
    let lang
    let hlOpts
    if (node.getStyle() === 'source') {
      syntaxHl = node.getDocument().syntaxHighlighter
      lang = node.getAttribute('language')
      if (syntaxHl) {
        const docAttrs = node.getDocument().getAttributes()
        const cssMode = docAttrs[`${syntaxHl.name}-css`] || 'class'
        const style = docAttrs[`${syntaxHl.name}-style`]
        hlOpts = syntaxHl.handlesHighlighting() ? { css_mode: cssMode, style } : {}
        hlOpts.nowrap = nowrap
      }
    }
    // data-id must not be declared on the <div> element (but on the <pre> element for auto-animate)
    const filteredAttrs = {}
    for (const [key, value] of Object.entries(node.getAttributes())) if (key !== 'data-id') filteredAttrs[key] = value
    const attrs = attributes({ id: node.getId(), class: ['listingblock', node.getRole(), step(node) ? 'fragment' : null], ...dataAttrs(filteredAttrs) })
    let buf = ''
    if (node.hasTitle()) buf += `<div class="title">${node.getCaptionedTitle()}</div>`
    buf += '<div class="content">'
    if (syntaxHl) {
      buf += (await syntaxHl.format(node, lang, hlOpts)) ?? ''
    } else if (node.getStyle() === 'source') {
      const code = `<code${attributes({ class: [lang ? `language-${lang}` : null], 'data-lang': lang ? String(lang) : null })}>${(await node.content()) || ''}</code>`
      buf += `<pre${attributes({ class: ['highlight', nowrap ? 'nowrap' : null] })}>${code}</pre>`
    } else {
      buf += `<pre${attributes({ class: [nowrap ? 'nowrap' : null] })}>${(await node.content()) || ''}</pre>`
    }
    buf += '</div>'
    return `<div${attrs}>${buf}</div>`
  }

  async convert_literal (node) {
    const attrs = attributes({ id: node.getId(), class: ['literalblock', node.getRole(), step(node) ? 'fragment' : null], ...dataAttrs(node.getAttributes()) })
    let buf = ''
    if (node.hasTitle()) buf += `<div class="title">${node.getTitle()}</div>`
    buf += '<div class="content">'
    buf += `<pre${attributes({ class: (!node.getDocument().hasAttribute('prewrap') || node.hasOption('nowrap')) ? 'nowrap' : null })}>${await node.content()}</pre>`
    buf += '</div>'
    return `<div${attrs}>${buf}</div>`
  }

  async convert_notes (node) {
    return `<aside class="notes">${await resolveContent(node)}</aside>`
  }

  async convert_open (node) {
    if (node.getStyle() === 'abstract') {
      if (node.getParent() === node.getDocument() && node.getDocument().getDoctype() === 'book') {
        console.log('asciidoctor: WARNING: abstract block cannot be used in a document without a title when doctype is book. Excluding block content.')
        return ''
      }
      const attrs = attributes({ id: node.getId(), class: ['quoteblock', 'abstract', node.getRole(), step(node) ? 'fragment' : null], ...dataAttrs(node.getAttributes()) })
      let buf = ''
      if (node.hasTitle()) buf += `<div class="title">${node.getTitle()}</div>`
      buf += `<blockquote>${await node.content()}</blockquote>`
      return `<div${attrs}>${buf}</div>`
    } else if (node.getStyle() === 'partintro' && (node.getLevel() !== 0 || node.getParent().getContext() !== 'section' || node.getDocument().getDoctype() !== 'book')) {
      console.log("asciidoctor: ERROR: partintro block can only be used when doctype is book and it's a child of a book part. Excluding block content.")
      return ''
    } else if (node.hasRole('aside') || node.hasRole('speaker') || node.hasRole('notes')) {
      return `<aside class="notes">${await resolveContent(node)}</aside>`
    }
    const attrs = attributes({ id: node.getId(), class: ['openblock', node.getStyle() === 'open' ? null : node.getStyle(), node.getRole(), step(node) ? 'fragment' : null], ...dataAttrs(node.getAttributes()) })
    let buf = ''
    if (node.hasTitle()) buf += `<div class="title">${node.getTitle()}</div>`
    buf += `<div class="content">${await node.content()}</div>`
    return `<div${attrs}>${buf}</div>`
  }

  convert_outline (node, opts = {}) {
    if (node.getSections().length === 0) return ''

    const toclevels = (opts && opts.toclevels) || parseInt(node.getDocument().getAttribute('toclevels', DEFAULT_TOCLEVELS), 10)
    const slevel = sectionLevel(node.getSections()[0])
    let buf = `<ol class="sectlevel${slevel}">`
    for (const sec of node.getSections()) {
      buf += `<li><a href="#${sec.getId()}">${sectionTitle(sec)}</a>`
      let childToc
      if (sec.getLevel() < toclevels && (childToc = this.convert(sec, 'outline'))) {
        buf += childToc ?? ''
      }
      buf += '</li>'
    }
    buf += '</ol>'
    return buf
  }

  convert_page_break () {
    return '<div style="page-break-after: always;"></div>'
  }

  async convert_pass (node) {
    return (await node.content()) ?? ''
  }

  async convert_quote (node) {
    const attrs = attributes({ id: node.getId(), class: ['quoteblock', node.getRole(), step(node) ? 'fragment' : null], ...dataAttrs(node.getAttributes()) })
    let buf = ''
    if (node.hasTitle()) buf += `<div class="title">${node.getTitle()}</div>`
    buf += `<blockquote>${await node.content()}</blockquote>`
    const attribution = node.hasAttribute('attribution') ? node.getAttribute('attribution') : null
    const citetitle = node.hasAttribute('citetitle') ? node.getAttribute('citetitle') : null
    if (attribution || citetitle) {
      buf += '<div class="attribution">'
      if (citetitle) buf += `<cite>${citetitle}</cite>`
      if (attribution) {
        if (citetitle) buf += '<br>'
        buf += `&#8212; ${attribution}`
      }
      buf += '</div>'
    }
    return `<div${attrs}>${buf}</div>`
  }

  convert_ruler () {
    return '<hr>'
  }

  async convert_sidebar (node) {
    if (node.hasRole('aside') || node.hasRole('speaker') || node.hasRole('notes')) {
      return `<aside class="notes">${await resolveContent(node)}</aside>`
    }
    const attrs = attributes({ id: node.getId(), class: ['sidebarblock', node.getRole(), stepOrRole(node) ? 'fragment' : null], ...dataAttrs(node.getAttributes()) })
    let buf = '<div class="content">'
    if (node.hasTitle()) buf += `<div class="title">${node.getTitle()}</div>`
    buf += (await node.content()) ?? ''
    buf += '</div>'
    return `<div${attrs}>${buf}</div>`
  }

  async convert_stem (node) {
    const [open, close] = BLOCK_MATH_DELIMITERS[node.getStyle()]
    let equation = (await node.content()).trim()
    const subs = node.getSubstitutions()
    if ((subs == null || subs.length === 0) && !node.hasAttribute('subs')) equation = node.subSpecialcharacters(equation)
    if (!(equation.startsWith(open) && equation.endsWith(close))) equation = `${open}${equation}${close}`
    const attrs = attributes({ id: node.getId(), class: ['stemblock', node.getRole(), stepOrRole(node) ? 'fragment' : null], ...dataAttrs(node.getAttributes()) })
    let buf = ''
    if (node.hasTitle()) buf += `<div class="title">${node.getTitle()}</div>`
    buf += `<div class="content">${equation}</div>`
    return `<div${attrs}>${buf}</div>`
  }

  async convert_table (node) {
    const classes = ['tableblock', `frame-${node.getAttribute('frame', 'all')}`, `grid-${node.getAttribute('grid', 'all')}`, node.getRole(), step(node) ? 'fragment' : null]
    const styles = [!node.hasOption('autowidth') ? `width:${node.getAttribute('tablepcwidth')}%` : null, node.hasAttribute('float') ? `float:${node.getAttribute('float')}` : null].filter((item) => item != null).join('; ')
    const attrs = attributes({ id: node.getId(), class: classes, style: styles, ...dataAttrs(node.getAttributes()) })
    let buf = ''
    if (node.hasTitle()) buf += `<caption class="title">${node.getCaptionedTitle()}</caption>`
    if (Number(node.getAttribute('rowcount')) !== 0) {
      buf += '<colgroup>'
      if (node.hasOption('autowidth')) {
        for (let i = 0; i < node.columns.length; i++) buf += '<col>'
      } else {
        for (const col of node.columns) buf += `<col style="width:${col.getAttribute('colpcwidth')}%">`
      }
      buf += '</colgroup>'
      const sections = [['head', node.rows.head], ['foot', node.rows.foot], ['body', node.rows.body]]
      for (const [tblsec, rows] of sections) {
        if (!rows || rows.length === 0) continue
        buf += `<t${tblsec}>`
        for (const row of rows) {
          buf += '<tr>'
          for (const cell of row) {
            let cellContent
            if (tblsec === 'head') cellContent = cell.text
            else if (cell.style === 'literal') cellContent = cell.text
            else cellContent = await cell.content()
            const cellAttrs = attributes({
              class: ['tableblock', `halign-${cell.getAttribute('halign')}`, `valign-${cell.getAttribute('valign')}`],
              colspan: cell.colspan,
              rowspan: cell.rowspan,
              style: node.getDocument().hasAttribute('cellbgcolor') ? `background-color:${node.getDocument().getAttribute('cellbgcolor')};` : null
            })
            let cellInner
            if (tblsec === 'head') cellInner = cellContent ?? ''
            else if (cell.style === 'asciidoc') cellInner = `<div>${cellContent}</div>`
            else if (cell.style === 'literal') cellInner = `<div class="literal"><pre>${cellContent}</pre></div>`
            else if (cell.style === 'header') cellInner = cellContent.map((text) => `<p class="tableblock header">${text}</p>`).join('')
            else cellInner = cellContent.map((text) => `<p class="tableblock">${text}</p>`).join('')
            const tag = (tblsec === 'head' || cell.style === 'header') ? 'th' : 'td'
            buf += `<${tag}${cellAttrs}>${cellInner}</${tag}>`
          }
          buf += '</tr>'
        }
        // NOTE: the Ruby converter does not emit a closing </thead>/</tbody>/</tfoot>.
      }
    }
    return `<table${attrs}>${buf}</table>`
  }

  convert_thematic_break () {
    return '<hr>'
  }

  convert_toc (node) {
    const content = `<div id="toctitle">${node.getDocument().getAttribute('toc-title')}</div>` + (this.convert(node.getDocument(), 'outline') ?? '')
    return `<div${attributes({ id: 'toc', class: node.getDocument().getAttribute('toc-class', 'toc') })}>${content}</div>`
  }

  async convert_verse (node) {
    const attrs = attributes({ id: node.getId(), class: ['verseblock', node.getRole(), step(node) ? 'fragment' : null], ...dataAttrs(node.getAttributes()) })
    let buf = ''
    if (node.hasTitle()) buf += `<div class="title">${node.getTitle()}</div>`
    buf += `<pre class="content">${await node.content()}</pre>`
    const attribution = node.hasAttribute('attribution') ? node.getAttribute('attribution') : null
    const citetitle = node.hasAttribute('citetitle') ? node.getAttribute('citetitle') : null
    if (attribution || citetitle) {
      buf += '<div class="attribution">'
      if (citetitle) buf += `<cite>${citetitle}</cite>`
      if (attribution) {
        if (citetitle) buf += '<br>'
        buf += `&#8212; ${attribution}`
      }
      buf += '</div>'
    }
    return `<div${attrs}>${buf}</div>`
  }

  async convert_video (node) {
    // in a slide-deck context we assume video should take as much place as possible unless already specified
    const noStretch = node.hasAttribute('width') || node.hasAttribute('height')
    const width = node.hasAttribute('width') ? node.getAttribute('width') : '100%'
    const height = node.hasAttribute('height') ? node.getAttribute('height') : '100%'
    const attrs = attributes({ id: node.getId(), class: ['videoblock', node.getStyle(), node.getRole(), noStretch ? null : 'stretch', stepOrRole(node) ? 'fragment' : null], ...dataAttrs(node.getAttributes()) })
    let buf = ''
    if (node.hasTitle()) buf += `<div class="title">${node.getCaptionedTitle()}</div>`
    const poster = node.getAttribute('poster')
    if (poster === 'vimeo') {
      let assetUriScheme = node.getAttribute('asset_uri_scheme', 'https')
      if (assetUriScheme !== '') assetUriScheme = `${assetUriScheme}:`
      const startAnchor = node.hasAttribute('start') ? `#at=${node.getAttribute('start')}` : null
      const delimiter = ['?']
      const loopParam = node.hasOption('loop') ? `${delimiter.pop() || '&amp;'}loop=1` : ''
      const mutedParam = node.hasOption('muted') ? `${delimiter.pop() || '&amp;'}muted=1` : ''
      const src = `${assetUriScheme}//player.vimeo.com/video/${node.getAttribute('target')}${loopParam}${mutedParam}${startAnchor ?? ''}`
      buf += `<iframe${attributes({ width, height, src, frameborder: 0, webkitAllowFullScreen: true, mozallowfullscreen: true, allowFullScreen: true, 'data-autoplay': node.hasOption('autoplay'), allow: node.hasOption('autoplay') ? 'autoplay' : null })}></iframe>`
    } else if (poster === 'youtube') {
      let assetUriScheme = node.getAttribute('asset_uri_scheme', 'https')
      if (assetUriScheme !== '') assetUriScheme = `${assetUriScheme}:`
      const params = ['rel=0']
      if (node.hasAttribute('start')) params.push(`start=${node.getAttribute('start')}`)
      if (node.hasAttribute('end')) params.push(`end=${node.getAttribute('end')}`)
      if (node.hasOption('loop')) params.push('loop=1')
      if (node.hasOption('muted')) params.push('mute=1')
      if (node.hasOption('nocontrols')) params.push('controls=0')
      const src = `${assetUriScheme}//www.youtube.com/embed/${node.getAttribute('target')}?${params.join('&amp;')}`
      buf += `<iframe${attributes({ width, height, src, frameborder: 0, allowfullscreen: !node.hasOption('nofullscreen'), 'data-autoplay': node.hasOption('autoplay'), allow: node.hasOption('autoplay') ? 'autoplay' : null })}></iframe>`
    } else {
      buf += `<video${attributes({ src: node.mediaUri(node.getAttribute('target')), width, height, poster: node.getAttribute('poster') ? node.mediaUri(node.getAttribute('poster')) : null, 'data-autoplay': node.hasOption('autoplay'), controls: !node.hasOption('nocontrols'), loop: node.hasOption('loop') })}>Your browser does not support the video tag.</video>`
    }
    return `<div${attrs}>${buf}</div>`
  }

  // ── Image helpers ────────────────────────────────────────────────────────────

  // Builds the inner markup of a block image (without its surrounding div).
  async imageContent (node) {
    // When the stretch class is present, block images take the most space they
    // can. Setting width and height can override that. We pin 100% to height to
    // avoid aspect ratio breakage.
    let heightValue
    if (node.hasRole('stretch') && !(node.hasAttribute('width') || node.hasAttribute('height'))) heightValue = '100%'
    else if (node.hasAttribute('height')) heightValue = node.getAttribute('height')
    let htmlAttrs = node.hasAttribute('width') ? ` width="${node.getAttribute('width')}"` : ''
    if (heightValue) htmlAttrs += ` height="${heightValue}"`
    if (node.hasAttribute('title')) htmlAttrs += ` title="${node.getAttribute('title')}"`
    if (node.hasAttribute('background')) htmlAttrs += ` style="background: ${node.getAttribute('background')}"`
    const [img, src] = await this.imgTag(node, node.getAttribute('target'), htmlAttrs)
    return this.imgLink(node, src, img)
  }

  // Builds the inner markup of an inline image (without its surrounding span).
  async inlineImageContent (node) {
    const target = node.getTarget()
    let img
    let src
    if ((node.getType() || 'image') === 'icon') {
      const icons = node.getDocument().getAttribute('icons')
      if (icons === 'font') {
        let iClass = `${node.getAttribute('set', 'fa')} fa-${target}`
        if (node.hasAttribute('size')) iClass += ` fa-${node.getAttribute('size')}`
        if (node.hasAttribute('flip')) iClass += ` fa-flip-${node.getAttribute('flip')}`
        else if (node.hasAttribute('rotate')) iClass += ` fa-rotate-${node.getAttribute('rotate')}`
        const attrs = node.hasAttribute('title') ? ` title="${node.getAttribute('title')}"` : ''
        img = `<i class="${iClass}"${attrs}></i>`
      } else if (node.getDocument().hasAttribute('icons')) {
        let attrs = node.hasAttribute('width') ? ` width="${node.getAttribute('width')}"` : ''
        if (node.hasAttribute('height')) attrs += ` height="${node.getAttribute('height')}"`
        if (node.hasAttribute('title')) attrs += ` title="${node.getAttribute('title')}"`
        src = await node.iconUri(target)
        img = `<img src="${src}" alt="${encodeAttributeValue(node.getAlt())}"${attrs}>`
      } else {
        img = `[${node.getAlt()}&#93;`
      }
    } else {
      let htmlAttrs = node.hasAttribute('width') ? ` width="${node.getAttribute('width')}"` : ''
      if (node.hasAttribute('height')) htmlAttrs += ` height="${node.getAttribute('height')}"`
      if (node.hasAttribute('title')) htmlAttrs += ` title="${node.getAttribute('title')}"`
      ;[img, src] = await this.imgTag(node, target, htmlAttrs)
    }
    return this.imgLink(node, src, img)
  }

  async imgTag (node, target, htmlAttrs) {
    let img
    let src
    if ((node.hasAttribute('format', 'svg') || target.includes('.svg')) && node.getDocument().safe < SafeMode.SECURE) {
      if (node.hasOption('inline')) {
        img = (await this.delegateConverter.readSvgContents(node, target)) || `<span class="alt">${node.getAlt()}</span>`
      } else if (node.hasOption('interactive')) {
        src = await node.imageUri(target)
        const fallback = node.hasAttribute('fallback')
          ? `<img src="${await node.imageUri(node.getAttribute('fallback'))}" alt="${encodeAttributeValue(node.getAlt())}"${htmlAttrs}>`
          : `<span class="alt">${node.getAlt()}</span>`
        img = `<object type="image/svg+xml" data="${src}"${htmlAttrs}>${fallback}</object>`
      } else {
        src = await node.imageUri(target)
        img = `<img src="${src}" alt="${encodeAttributeValue(node.getAlt())}"${htmlAttrs}>`
      }
    } else {
      src = await node.imageUri(target)
      img = `<img src="${src}" alt="${encodeAttributeValue(node.getAlt())}"${htmlAttrs}>`
    }
    return [img, src]
  }

  // Wrap the <img> element in an <a> element if the link attribute is defined.
  imgLink (node, src, content) {
    if (node.hasAttribute('link')) {
      let hrefAttrVal = node.getAttribute('link')
      if (hrefAttrVal === 'self') hrefAttrVal = src
      let dataPreviewAttr = ''
      const linkPreviewValue = boolDataAttr(node, 'link_preview')
      if (linkPreviewValue) dataPreviewAttr = ` data-preview-link="${linkPreviewValue === true ? '' : linkPreviewValue}"`
      return `<a class="image" href="${hrefAttrVal}"${appendLinkConstraintAttrs(node).join('')}${dataPreviewAttr}>${content}</a>`
    }
    return content
  }

  // ── Document helpers ─────────────────────────────────────────────────────────

  // Generate the MathJax markup to process STEM expressions.
  generateStem (node, cdnBase) {
    if (!node.hasAttribute('stem')) return undefined

    let eqnumsVal = String(node.getAttribute('eqnums', STEM_EQNUMS_NONE)).toLowerCase()
    if (!STEM_EQNUMS_VALID_VALUES.includes(eqnumsVal)) eqnumsVal = STEM_EQNUMS_AMS
    const mathjaxConfiguration = {
      tex: {
        inlineMath: [INLINE_MATH_DELIMITERS.latexmath],
        displayMath: [BLOCK_MATH_DELIMITERS.latexmath],
        processEscapes: false,
        tags: eqnumsVal
      },
      options: {
        ignoreHtmlClass: 'nostem|nolatexmath'
      },
      asciimath: {
        delimiters: [BLOCK_MATH_DELIMITERS.asciimath]
      },
      loader: {
        load: ['input/asciimath', 'output/chtml', 'ui/menu']
      }
    }
    const mathjaxdir = node.getAttribute('mathjaxdir', `${cdnBase}/mathjax/${MATHJAX_VERSION}/es5`)
    return `<script>window.MathJax = ${JSON.stringify(mathjaxConfiguration)};</script>` +
      `<script async src="${mathjaxdir}/tex-mml-chtml.js"></script>`
  }

  // Copied from asciidoctor semantic-html5 converter (not yet shipped).
  async generateAuthors (node) {
    const authors = node.authors()
    if (authors.length === 0) return undefined

    if (authors.length === 1) {
      // NOTE: the two-space indentation is kept to preserve byte-for-byte
      // compatibility with the output produced by the former Slim pipeline.
      return `<p class="byline">\n  ${await this.formatAuthor(node, authors[0])}\n  </p>`
    }
    const result = ['<ul class="byline">']
    for (const author of authors) {
      result.push(`<li>${await this.formatAuthor(node, author)}</li>`)
    }
    result.push('</ul>')
    return result.join('\n')
  }

  async formatAuthor (node, author) {
    const email = author.getEmail()
    return `<span class="author">${node.subReplacements(author.getName())}${email ? ` ${await node.subMacros(email)}` : ''}</span>`
  }
}

export { DEFAULT_TOCLEVELS, sectionLevel, sectionTitle }
