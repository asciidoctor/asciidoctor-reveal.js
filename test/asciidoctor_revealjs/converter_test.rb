# frozen_string_literal: true

require_relative '../test_helper'

module Asciidoctor
  module Revealjs
    class ConverterTest < Minitest::Test
      def convert(source, attributes = {})
        ::Asciidoctor.convert source, safe: :safe, backend: 'revealjs', header_footer: false, attributes: attributes
      end

      # Registers a docinfo_processor extension at +location+ that inserts +marker+, scoped
      # to this single conversion (no docinfo file on disk, no attributes/document required).
      def convert_standalone(source, locations_to_markers = {}, attributes = {})
        ::Asciidoctor.convert source, safe: :safe, backend: 'revealjs', header_footer: true, attributes: attributes,
                                      extensions: proc {
                                        locations_to_markers.each do |location, marker|
                                          docinfo_processor location: location do
                                            process { marker }
                                          end
                                        end
                                      }
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

      def test_header_and_body_header_alias_land_just_inside_body_before_the_reveal_div
        html = convert_standalone <<~ADOC, header: '<div id="header"></div>', 'body-header': '<div id="body-header"></div>'
          = Title

          == Slide

          Content
        ADOC

        assert_includes html, '<body><div id="header"></div><div id="body-header"></div><div class="reveal">'
      end

      def test_footer_and_body_footer_alias_land_just_inside_body_after_reveal_initialize
        html = convert_standalone <<~ADOC, footer: '<div id="footer"></div>', 'body-footer': '<div id="body-footer"></div>'
          = Title

          == Slide

          Content
        ADOC

        assert_match(%r{Reveal\.initialize.*</script><div id="footer"></div><div id="body-footer"></div></body>}m, html)
      end

      def test_slides_header_and_slides_footer_land_at_the_boundaries_of_the_slides_div
        html = convert_standalone <<~ADOC, 'slides-header': '<div id="slides-header"></div>', 'slides-footer': '<div id="slides-footer"></div>'
          = Title

          == Slide

          Content
        ADOC

        assert_includes html, '<div class="slides"><div id="slides-header"></div><section class="title"'
        assert_includes html, '</section><div id="slides-footer"></div></div></div>'
      end

      def test_slide_header_and_slide_footer_land_in_every_section
        html = convert_standalone <<~ADOC, 'slide-header': '<div class="slide-header"></div>', 'slide-footer': '<div class="slide-footer"></div>'
          = Title

          == Slide one

          Content 1

          == Slide two

          Content 2
        ADOC

        assert_equal 2, html.scan('<div class="slide-header"></div>').length
        assert_equal 2, html.scan('<div class="slide-footer"></div>').length
        assert_includes html, '<section id="_slide_one"><div class="slide-header"></div><h2>Slide one</h2>'
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

      def test_collapsible_example_block_renders_as_a_details_element
        html = convert <<~ADOC
          [%collapsible]
          ====
          Hidden content.
          ====
        ADOC

        assert_includes html, '<details><summary class="title">Details</summary><div class="content">'
        refute_includes html, 'exampleblock'
      end

      def test_collapsible_example_block_uses_its_title_as_the_summary
        html = convert <<~ADOC
          [%collapsible]
          .Custom summary
          ====
          Hidden content.
          ====
        ADOC

        assert_includes html, '<summary class="title">Custom summary</summary>'
      end

      def test_collapsible_example_block_with_open_option_starts_expanded
        html = convert <<~ADOC
          [%collapsible%open]
          ====
          Visible content.
          ====
        ADOC

        assert_includes html, '<details open>'
      end

      def test_non_collapsible_example_block_is_unaffected
        html = convert <<~ADOC
          ====
          Regular content.
          ====
        ADOC

        assert_includes html, '<div class="exampleblock">'
        refute_includes html, '<details'
      end
    end
  end
end
