// Port of the Footnotes module in lib/asciidoctor_revealjs/converter.rb
//
// Display footnotes per slide. Footnotes declared on a section title are
// processed during parsing/substitution, so they are stored separately to be
// displayed on the right slide/section.
//
// Stored footnotes are plain objects { index, id, text } (the Ruby code uses
// Asciidoctor::Document::Footnote, but only index/text are read back).

import { Inline } from '@asciidoctor/core'

// footnote index (initial) -> stored footnote { index, id, text }
let slideFootnotesByIndex = new Map()
// section node (by identity) -> array of footnotes { index, id, text }
const sectionFootnotes = new Map()

function isSection (node) {
  return node != null && typeof node.getContext === 'function' && node.getContext() === 'section'
}

export function slideFootnote (footnote) {
  const footnoteParent = footnote.getParent()
  let inlineFootnote
  // footnotes declared on the section title are processed during the
  // parsing/substitution; store them to display them on the right slide/section.
  if (isSection(footnoteParent)) {
    const sectionFn = sectionFootnotes.get(footnoteParent) || []
    const footnoteIndex = sectionFn.length + 1
    const attributes = { ...footnote.getAttributes(), index: footnoteIndex }
    inlineFootnote = new Inline(footnoteParent, footnote.getContext(), footnote.getText(), { attributes })
    sectionFn.push({ index: inlineFootnote.getAttribute('index'), id: inlineFootnote.getId(), text: inlineFootnote.getText() })
    sectionFootnotes.set(footnoteParent, sectionFn)
  } else {
    let parent = footnote.getParent()
    while (parent != null && !isSection(parent)) parent = parent.getParent()
    // check if there is any footnote attached on the section title
    const sectionFn = parent == null ? [] : (sectionFootnotes.get(parent) || [])
    const initialIndex = footnote.getAttribute('index')
    // reset the footnote numbering to 1 on each slide; reuse the same index when
    // a footnote is used more than once.
    const existingFootnote = slideFootnotesByIndex.get(initialIndex)
    const slideIndex = existingFootnote ? existingFootnote.index : slideFootnotesByIndex.size + sectionFn.length + 1
    const attributes = { ...footnote.getAttributes(), index: slideIndex }
    inlineFootnote = new Inline(footnoteParent, footnote.getContext(), footnote.getText(), { attributes })
    slideFootnotesByIndex.set(initialIndex, { index: inlineFootnote.getAttribute('index'), id: inlineFootnote.getId(), text: inlineFootnote.getText() })
  }
  return inlineFootnote
}

export function clearSlideFootnotes () {
  slideFootnotesByIndex = new Map()
}

export function slideFootnotes (section) {
  const sectionFn = sectionFootnotes.get(section) || []
  return [...sectionFn, ...slideFootnotesByIndex.values()]
}
