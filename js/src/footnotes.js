// Port of the Footnotes module in lib/asciidoctor_revealjs/converter.rb
//
// Display footnotes per slide. Footnotes are numbered from 1 again on every
// slide; a footnote referenced more than once on the same slide keeps its
// number. Outside of a slide (embedded conversion, deck without sections,
// preamble), footnotes are numbered continuously, like Ruby does.
//
// The Asciidoctor.js 4 core substitutes some text eagerly, before (or out of)
// conversion order: list items, table cells, block titles and AsciiDoc table
// cells (whose nested documents are converted before the root document). The
// core footnote indexes are therefore not usable (with 4.1 they are even
// placeholders that the core only resolves when it renders the text itself).
//
// Instead, a footnote in the body of a slide (or outside of any slide) first
// gets a placeholder as its number. The placeholders are replaced by real
// numbers in the order they appear in the converted HTML of the slide (see
// resolveSlideFootnotes) or of the document (see resolveDocumentFootnotes),
// which is the document order. Footnotes declared on a section title are
// numbered right away, before the body footnotes of the slide.
//
// The footnote lists rendered by the embedded converter (the root document and
// the nested documents of AsciiDoc table cells) use document-wide numbers, as the
// Ruby core does: each footnote gets the next number the first time one of its
// placeholders is resolved. These numbers are written as "global" placeholders
// first and replaced at the end of the conversion (see resolveGlobalFootnotes).
//
// All the state is attached to the root document in a WeakMap, so it is released
// together with the document.

import { Inline } from 'asciidoctor'

const PLACEHOLDER_MARK = '\u0001\u0001'
const LOCAL_PLACEHOLDER_RX = /\u0001\u0001slide-fn:(\d+)\u0001\u0001/g
const GLOBAL_PLACEHOLDER_RX = /\u0001\u0001global-fn:(\d+)\u0001\u0001/g

// root document -> conversion state
const states = new WeakMap()

function rootDocument (doc) {
  while (doc.parentDocument) doc = doc.parentDocument
  return doc
}

function stateOf (node) {
  const root = rootDocument(node.getDocument())
  let state = states.get(root)
  if (state == null) {
    state = {
      // key -> entry { key, doc, id, text, defined }; the key identifies a footnote (a
      // footnote with an id and the references to it share a key)
      entries: [],
      // owner document -> Map(id -> entry)
      ids: new Map(),
      // section -> footnotes { index, id, text } declared on its title
      titleFootnotes: new Map(),
      // section -> footnotes { index, id, text } displayed on its slide (title, then body)
      slideFootnotes: new Map(),
      // entries in the order they were first numbered (document-wide numbering)
      globalOrder: [],
      globalNumbers: new Map(),
      globalCounter: 0,
      // section -> entries declared on its title (Map: kept in substitution order)
      titleEntries: new Map(),
      started: false,
      // numbering of the footnotes outside of a slide: entry key -> number
      docNumbers: new Map()
    }
    states.set(root, state)
  }
  return state
}

function localPlaceholder (entry) {
  return `${PLACEHOLDER_MARK}slide-fn:${entry.key}${PLACEHOLDER_MARK}`
}

function globalPlaceholder (entry) {
  return `${PLACEHOLDER_MARK}global-fn:${entry.key}${PLACEHOLDER_MARK}`
}

// A reference to an undefined footnote is not numbered nor listed, like in the core.
function recordGlobal (state, entry) {
  if (!entry.defined || state.globalNumbers.has(entry.key)) return
  state.globalOrder.push(entry)
  state.globalNumbers.set(entry.key, ++state.globalCounter)
}

function isSection (node) {
  return node != null && typeof node.getContext === 'function' && node.getContext() === 'section'
}

// Find (or create) the entry of a footnote. A footnote with an id can be referenced
// again; a definition carries the id on `getId()`, a later reference carries it on
// `getTarget()`. Anonymous footnotes (neither) are always distinct.
function footnoteEntry (state, footnote, text) {
  const doc = footnote.getDocument()
  const id = footnote.getId() || footnote.getTarget()
  let ids = state.ids.get(doc)
  if (ids == null) state.ids.set(doc, (ids = new Map()))
  let entry = id ? ids.get(id) : null
  if (entry == null) {
    entry = { key: state.entries.length, doc, id, text, defined: false }
    state.entries.push(entry)
    if (id) ids.set(id, entry)
  }
  // A definition carries its id (or no id at all, if anonymous), a reference only a target.
  if (footnote.getId() || !footnote.getTarget()) entry.defined = true
  // A reference in a list item or table cell is substituted before the definition
  // above it, so the entry was created with the fallback text; use the definition's.
  if (footnote.getId()) entry.text = text
  return entry
}

export function slideFootnote (footnote) {
  const state = stateOf(footnote)
  const footnoteParent = footnote.getParent()
  // Footnotes declared on the section title are stored against that section so
  // they show up on its slide.
  if (isSection(footnoteParent)) {
    const sectionFn = state.titleFootnotes.get(footnoteParent) || []
    const index = sectionFn.length + 1
    const inlineFootnote = new Inline(footnoteParent, footnote.getContext(), footnote.getText(), { attributes: { ...footnote.getAttributes(), index } })
    sectionFn.push({ index, id: inlineFootnote.getId(), text: inlineFootnote.getText() })
    state.titleFootnotes.set(footnoteParent, sectionFn)
    // numbered document-wide later, see startDocument and recordTitleFootnotes
    const titleEntries = state.titleEntries.get(footnoteParent) || []
    titleEntries.push(footnoteEntry(state, footnote, inlineFootnote.getText()))
    state.titleEntries.set(footnoteParent, titleEntries)
    return inlineFootnote
  }

  const entry = footnoteEntry(state, footnote, footnote.getText())
  let index = localPlaceholder(entry)
  // The inline doctype converts a single block, without going through the document
  // converter that resolves the placeholders, and is substituted in order.
  const doc = footnote.getDocument()
  if (doc.getDoctype() === 'inline') index = resolveDocumentFootnotes(doc, index)
  return new Inline(footnoteParent, footnote.getContext(), footnote.getText(), { attributes: { ...footnote.getAttributes(), index } })
}

// Replace the local placeholders in `html` with numbers, in order of appearance,
// continuing from `numbers` (entry key -> number). Returns the HTML and the newly
// numbered entries.
function resolveLocal (state, html, numbers, first) {
  let next = first
  const numbered = []
  const resolved = html.replace(LOCAL_PLACEHOLDER_RX, (placeholder, key) => {
    const entry = state.entries[Number(key)]
    if (entry == null) return ''
    if (!numbers.has(entry.key)) {
      numbers.set(entry.key, next++)
      numbered.push(entry)
      recordGlobal(state, entry)
    }
    return String(numbers.get(entry.key))
  })
  return { html: resolved, numbered }
}

// Number the footnotes of the slide in the order their placeholders appear in its HTML,
// after the footnotes declared on its title, and return the HTML with the numbers.
export function resolveSlideFootnotes (section, html) {
  const state = stateOf(section)
  const titleFn = state.titleFootnotes.get(section) || []
  const numbers = new Map()
  const { html: resolved, numbered } = resolveLocal(state, html, numbers, titleFn.length + 1)
  state.slideFootnotes.set(section, [...titleFn, ...numbered.map((entry) => ({ index: numbers.get(entry.key), id: entry.id, text: entry.text }))])
  // Like Ruby (which clears its slide footnotes after each slide), the numbering of the
  // footnotes outside of a slide starts over after a slide.
  state.docNumbers = new Map()
  return resolved
}

export function slideFootnotes (section) {
  return stateOf(section).slideFootnotes.get(section) || []
}

// Start the conversion of a root document: the numbering of the footnotes outside of a
// slide starts at 1 (in case the document is converted more than once).
export function startDocument (doc) {
  const state = stateOf(doc)
  state.docNumbers = new Map()
  // Like the core, the document-wide numbering starts over after the parsing: the
  // footnotes of the section titles substituted while parsing are numbered from 1, then
  // the other footnotes are numbered from 1 again. Ruby only substitutes the title of a
  // section while parsing to generate its id (the section has no explicit id).
  if (!state.started) {
    state.started = true
    const header = doc.getHeader()
    for (const [section, entries] of state.titleEntries) {
      if (section !== header && !section.hasAttribute('id') && section.getId()) entries.forEach((entry) => recordGlobal(state, entry))
    }
    state.globalCounter = 0
  }
}

// Number document-wide the footnotes declared on the title of a section (or of the
// document header) when the title is converted, which is when Ruby substitutes the
// titles that were not substituted while parsing (see startDocument).
export function recordTitleFootnotes (section) {
  if (section == null) return
  const state = stateOf(section)
  for (const entry of state.titleEntries.get(section) || []) recordGlobal(state, entry)
}

// Number the footnotes outside of any slide (document without sections, preamble)
// in the order their placeholders appear in `html`, continuing the numbering of the
// previous parts of the document converted outside of a slide.
export function resolveDocumentFootnotes (doc, html) {
  if (html == null) return html
  const state = stateOf(doc)
  return resolveLocal(state, html, state.docNumbers, state.docNumbers.size + 1).html
}

// Footnotes of a document (root or nested) to list at the end of the embedded output,
// as { index, text } where index is a global placeholder (see resolveGlobalFootnotes).
// The footnotes of the root document are listed in document-wide order. The footnotes
// of a nested document are listed in the order they appear in its content, because
// they are not numbered yet (nested documents are converted before the root document).
export function documentFootnotes (doc, content = '') {
  const state = stateOf(doc)
  let entries
  if (doc.parentDocument) {
    entries = []
    for (const [, key] of content.matchAll(LOCAL_PLACEHOLDER_RX)) {
      const entry = state.entries[Number(key)]
      if (entry != null && entry.defined && entry.doc === doc && !entries.includes(entry)) entries.push(entry)
    }
  } else {
    entries = state.globalOrder.filter((entry) => entry.doc === doc)
  }
  return entries.map((entry) => ({ index: globalPlaceholder(entry), text: entry.text }))
}

// Replace the global placeholders with document-wide numbers. Must run last, once all
// the footnotes of the document have been numbered, so that no placeholder reaches the
// output. A local placeholder left at this point is numbered like a footnote outside of
// a slide.
export function resolveGlobalFootnotes (doc, html) {
  if (html == null) return html
  const state = stateOf(doc)
  return resolveDocumentFootnotes(doc, html).replace(GLOBAL_PLACEHOLDER_RX, (placeholder, key) => {
    const entry = state.entries[Number(key)]
    if (entry == null) return ''
    recordGlobal(state, entry)
    return String(state.globalNumbers.get(entry.key) ?? '')
  })
}
