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

function isSection (node) {
  return node != null && typeof node.getContext === 'function' && node.getContext() === 'section'
}

// Walk up to the section (slide) that contains the footnote.
function enclosingSection (node) {
  let parent = node.getParent()
  while (parent != null && !isSection(parent)) parent = parent.getParent()
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
  const titleFn = section == null ? [] : (titleFootnotes.get(section) || [])
  const bodyFn = section == null ? [] : (bodyFootnotes.get(section) || [])
  // A footnote with an id can be referenced again on the same slide; reuse its
  // number. A definition carries the id on `getId()`, a later reference carries
  // it on `getTarget()`. Anonymous footnotes (neither) are always distinct.
  const id = footnote.getId() || footnote.getTarget()
  const existing = id ? bodyFn.find((fn) => fn.id === id) : null
  const index = existing ? existing.index : titleFn.length + bodyFn.length + 1
  const inlineFootnote = new Inline(footnoteParent, footnote.getContext(), footnote.getText(), { attributes: { ...footnote.getAttributes(), index } })
  if (!existing && section != null) {
    bodyFn.push({ index, id, text: inlineFootnote.getText() })
    bodyFootnotes.set(section, bodyFn)
  }
  return inlineFootnote
}

export function slideFootnotes (section) {
  return [...(titleFootnotes.get(section) || []), ...(bodyFootnotes.get(section) || [])]
}
