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
    end
  end
end
