# frozen_string_literal: true

require_relative '../test_helper'

module Asciidoctor
  module Revealjs
    class ConverterTest < Minitest::Test
      def convert(source, attributes = {})
        ::Asciidoctor.convert source, safe: :safe, backend: 'revealjs', header_footer: false, attributes: attributes
      end

      def test_embedded_title_is_wrapped_in_a_title_slide_section_not_a_bare_h1
        html = convert <<~ADOC, 'showtitle' => ''
          = My Title

          == Slide one

          Content
        ADOC

        assert_includes html, '<section class="title" data-state="title"><h1>My Title</h1></section>'
        refute_match(/^<h1/, html)
      end

      def test_embedded_conversion_omits_the_title_by_default
        html = convert <<~ADOC
          = My Title

          == Slide one

          Content
        ADOC

        refute_includes html, 'My Title'
      end

      def test_unstyled_list_gets_the_asciidoctor_default_no_bullet_css
        html = ::Asciidoctor.convert <<~ADOC, safe: :safe, backend: 'revealjs', header_footer: true
          = Title

          == Slide

          [unstyled]
          * one
          * two
        ADOC

        assert_includes html, '<ul class="unstyled">'
        assert_includes html, 'ul.unstyled, ol.unstyled {
  margin-left: 0
}'
      end

      def test_toc_omits_titleless_slides
        html = convert <<~ADOC
          = Example

          == !
          toc::[]

          == Slide 1

          content

          == Slide 2

          content

          === Sub slide

          nested
        ADOC

        refute_includes html, '>!<'
        assert_includes html, '<li><a href="#_slide_1">Slide 1</a></li>'
        assert_includes html, '<li><a href="#_sub_slide">Sub slide</a></li>'
      end

      def test_quoteblock_attribution_gets_the_asciidoctor_default_right_alignment_css
        html = ::Asciidoctor.convert <<~ADOC, safe: :safe, backend: 'revealjs', header_footer: true
          = Title

          == Slide

          [quote,Author]
          ____
          Quoted text.
          ____
        ADOC

        assert_includes html, '<div class="attribution">'
        assert_includes html, '.reveal .quoteblock .attribution {
  margin-top: .75em;
  margin-right: .5ex;
  text-align: right
}'
      end

      def test_r_stack_open_block_does_not_wrap_content_in_a_content_div
        # reveal.js's .r-stack CSS targets *direct* children (`.r-stack > *`) to
        # stack them on top of each other; the usual .content wrapper would put
        # each image one level too deep for that selector to reach (#520).
        html = convert <<~ADOC
          [.r-stack]
          --
          image::before.png[]

          image::after.png[]
          --
        ADOC

        assert_includes html, '<div class="openblock r-stack"><div class="imageblock">'
        refute_includes html, '<div class="openblock r-stack"><div class="content">'
      end

      def test_normal_open_block_still_gets_a_content_div
        html = convert <<~ADOC
          [.custom]
          --
          Some content
          --
        ADOC

        assert_includes html, '<div class="openblock custom"><div class="content">'
      end

      def test_table_rowstep_option_applies_fragment_to_each_body_row
        html = convert <<~ADOC
          [%rowstep,cols="1,1",options=header]
          |===
          |Name |Category

          |Firefox |Browser
          |Chrome |Browser
          |===
        ADOC

        assert_includes html, '<thead><tr><th'
        refute_includes html, '<thead><tr class="fragment">'
        assert_equal 2, html.scan('<tr class="fragment">').length
      end

      def test_table_without_rowstep_option_has_plain_rows
        html = convert <<~ADOC
          [cols="1,1",options=header]
          |===
          |Name |Category

          |Firefox |Browser
          |===
        ADOC

        refute_includes html, 'class="fragment"'
      end
    end
  end
end
