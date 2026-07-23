# frozen_string_literal: true

require_relative '../test_helper'

module Asciidoctor
  module Revealjs
    class HighlightjsTest < Minitest::Test
      def convert(source, attributes = {})
        ::Asciidoctor.convert source, safe: :safe, backend: 'revealjs', header_footer: true,
                                      attributes: { 'source-highlighter' => 'highlightjs' }.merge(attributes)
      end

      def test_code_block_gets_the_hljs_language_class
        html = convert <<~ADOC
          [source,ruby]
          ----
          puts 'hi'
          ----
        ADOC

        assert_includes html, 'class="language-ruby hljs"'
      end

      def test_code_block_without_a_language_falls_back_to_none
        html = convert <<~ADOC
          [source]
          ----
          plain text
          ----
        ADOC

        assert_includes html, 'class="language-none hljs"'
      end

      def test_linenums_attribute_enables_line_numbers_without_a_range
        html = convert <<~ADOC
          [source%linenums,ruby]
          ----
          puts 'hi'
          ----
        ADOC

        assert_includes html, 'data-line-numbers=""'
      end

      def test_highlight_attribute_expands_a_range_into_individual_line_numbers
        html = convert <<~ADOC
          [source,ruby,highlight="1..3"]
          ----
          a
          b
          c
          ----
        ADOC

        assert_includes html, 'data-line-numbers="1,2,3"'
      end

      def test_highlight_attribute_supports_reveal_js_steps_separated_by_pipe
        html = convert <<~ADOC
          [source,ruby,highlight="1..2|4"]
          ----
          a
          b
          c
          d
          ----
        ADOC

        assert_includes html, 'data-line-numbers="1,2|4"'
      end

      def test_trim_option_adds_data_trim
        html = convert <<~ADOC
          [source%trim,ruby]
          ----

          puts 'hi'

          ----
        ADOC

        assert_includes html, 'data-trim=""'
      end

      def test_docinfo_uses_the_default_monokai_theme_by_default
        html = convert 'no code blocks here'

        assert_includes html, 'dist/plugin/highlight/monokai.css'
      end

      def test_docinfo_honors_a_custom_theme_attribute
        html = convert 'no code blocks here', 'highlightjs-theme' => 'https://example.org/theme.css'

        assert_includes html, 'https://example.org/theme.css'
      end

      def test_docinfo_adds_a_script_tag_for_each_requested_language
        html = convert 'no code blocks here', 'highlightjs-languages' => 'ruby,yaml'

        assert_includes html, 'languages/ruby.min.js'
        assert_includes html, 'languages/yaml.min.js'
      end
    end
  end
end
