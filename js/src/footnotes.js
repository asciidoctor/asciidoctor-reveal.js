// Port of the Footnotes module in lib/asciidoctor_revealjs/converter.rb
//
// Display footnotes per slide. Footnotes are numbered from 1 again on every
// slide; a footnote referenced more than once on the same slide keeps its
// number. Footnotes are bucketed by the section (slide) that contains them,
// keyed by node identity, so the result does not depend on the order in which
// Asciidoctor.js substitutes them.
//
// This independence matters with the Asciidoctor.js 4.0 core: footnotes inside
// list items (and on section titles) are substituted eagerly, before any slide
// is rendered, and the core's `index` attribute is not a reliable document-wide
// identifier. Bucketing by the enclosing section and de-duplicating reused
// footnotes by their id avoids relying on either.
//
// Stored footnotes are plain objects { index, id, text } (the Ruby code uses
// Asciidoctor::Document::Footnote, but only index/text are read back).

import { Inline } from 'asciidoctor'

// section node (by identity) -> array of footnotes { index, id, text } declared
// on the section title.
const titleFootnotes = new Map()
// section node (by identity) -> array of footnotes { index, id, text } declared
// in the section body.
const bodyFootnotes = new Map()

// A footnote in the body of a slide first gets a placeholder as its number, because
// list item and table cell text is substituted before the slides are converted. The
// placeholders are replaced by the real numbers in the order they appear in the slide
// (see resolveSlideFootnotes), which is the document order.
const PLACEHOLDER_MARK = '\u0001\u0001'
const PLACEHOLDER_RX = /\u0001\u0001slide-fn:\d+\u0001\u0001/g
let placeholderSeq = 0

function isSection (node) {
  return node != null && typeof node.getContext === 'function' && node.getContext() === 'section'
}

// Levels 1/2 render as an actual <section> slide; level 3+ renders inline as a
// dynamic <h3>/<h4>/... heading (see convert_section), so it never calls
// slideFootnotes() itself. A footnote bucketed against one of those would be
// stored but never read back, so walk past them to the enclosing slide.
function isSlideSection (node) {
  return isSection(node) && node.getLevel() <= 2
}

// Walk up to the section (slide) that contains the footnote.
function enclosingSection (node) {
  let parent = node.getParent()
  while (parent != null && !isSlideSection(parent)) parent = parent.getParent()
  return parent
}

export function slideFootnote (footnote) {
  const footnoteParent = footnote.getParent()
  // Footnotes declared on the section title are stored against that section so
  // they show up on its slide.
  if (isSection(footnoteParent)) {
    const sectionFn = titleFootnotes.get(footnoteParent) || []
    const index = sectionFn.length + 1
    const inlineFootnote = new Inline(footnoteParent, footnote.getContext(), footnote.getText(), { attributes: { ...footnote.getAttributes(), index } })
    sectionFn.push({ index, id: inlineFootnote.getId(), text: inlineFootnote.getText() })
    titleFootnotes.set(footnoteParent, sectionFn)
    return inlineFootnote
  }

  const section = enclosingSection(footnote)
  // Outside any section (embedded conversion, or content before the first
  // slide), fall back to the document itself so these footnotes still get a
  // stable bucket to dedupe against, instead of never being stored at all.
  const bucketKey = section ?? footnote.getDocument()
  const titleFn = section == null ? [] : (titleFootnotes.get(section) || [])
  const bodyFn = bodyFootnotes.get(bucketKey) || []
  // A footnote with an id can be referenced again on the same slide; reuse its
  // number. A definition carries the id on `getId()`, a later reference carries
  // it on `getTarget()`. Anonymous footnotes (neither) are always distinct.
  const id = footnote.getId() || footnote.getTarget()
  const existing = id ? bodyFn.find((fn) => fn.id === id) : null
  let index
  if (existing) index = existing.index
  else if (section == null) index = titleFn.length + bodyFn.length + 1
  else index = `${PLACEHOLDER_MARK}slide-fn:${placeholderSeq++}${PLACEHOLDER_MARK}`
  const inlineFootnote = new Inline(footnoteParent, footnote.getContext(), footnote.getText(), { attributes: { ...footnote.getAttributes(), index } })
  if (!existing) {
    bodyFn.push({ index, id, text: inlineFootnote.getText() })
    bodyFootnotes.set(bucketKey, bodyFn)
  }
  return inlineFootnote
}

// Number the footnotes of the slide in the order their placeholders appear in its HTML,
// after the footnotes declared on its title, and return the HTML with the numbers.
export function resolveSlideFootnotes (section, html) {
  const bodyFn = bodyFootnotes.get(section) || []
  const numbers = new Map()
  let next = (titleFootnotes.get(section) || []).length + 1
  const resolved = html.replace(PLACEHOLDER_RX, (placeholder) => {
    if (!numbers.has(placeholder)) numbers.set(placeholder, next++)
    return String(numbers.get(placeholder))
  })
  for (const fn of bodyFn) {
    if (typeof fn.index !== 'string') continue
    if (!numbers.has(fn.index)) numbers.set(fn.index, next++)
    fn.index = numbers.get(fn.index)
  }
  bodyFn.sort((a, b) => a.index - b.index)
  return resolved
}

export function slideFootnotes (section) {
  return [...(titleFootnotes.get(section) || []), ...(bodyFootnotes.get(section) || [])]
}
