# frozen_string_literal: true

require_relative '../test_helper'

module Asciidoctor
  module Revealjs
    class RevealJsOptionsTest < Minitest::Test
      def doc(attributes = {})
        Asciidoctor.load '= Title', attributes: attributes
      end

      # -- to_boolean --

      def test_to_boolean_treats_the_string_false_as_false
        refute RevealJsOptions.to_boolean('false')
      end

      def test_to_boolean_treats_the_string_zero_as_false
        refute RevealJsOptions.to_boolean('0')
      end

      def test_to_boolean_treats_nil_as_false
        refute RevealJsOptions.to_boolean(nil)
      end

      def test_to_boolean_treats_any_other_value_as_true
        assert RevealJsOptions.to_boolean('true')
        assert RevealJsOptions.to_boolean(true)
        assert RevealJsOptions.to_boolean('')
      end

      # -- to_valid_slidenumber --

      def test_to_valid_slidenumber_treats_empty_string_as_true
        assert(RevealJsOptions.to_valid_slidenumber(''))
      end

      def test_to_valid_slidenumber_treats_the_string_false_as_false
        refute(RevealJsOptions.to_valid_slidenumber('false'))
      end

      def test_to_valid_slidenumber_treats_the_boolean_false_as_false
        refute(RevealJsOptions.to_valid_slidenumber(false))
      end

      def test_to_valid_slidenumber_quotes_any_other_value
        assert_equal "'h.v'", (RevealJsOptions.to_valid_slidenumber 'h.v')
      end

      # -- format_value --

      def test_format_value_formats_bool
        assert(RevealJsOptions.format_value(:bool, 'true'))
      end

      def test_format_value_formats_slidenumber
        assert_equal "'c'", (RevealJsOptions.format_value :slidenumber, 'c')
      end

      def test_format_value_formats_string_by_single_quoting_it
        assert_equal "'slide'", (RevealJsOptions.format_value :string, 'slide')
      end

      def test_format_value_leaves_raw_values_untouched
        assert_equal 3, (RevealJsOptions.format_value :raw, 3)
      end

      # -- render_options --

      def test_render_options_uses_the_default_when_the_attribute_is_absent
        assert_match(/controls: true,/, (RevealJsOptions.render_options doc))
      end

      def test_render_options_uses_the_attribute_value_when_present
        assert_match(/controls: false,/, (RevealJsOptions.render_options doc('revealjs_controls' => 'false')))
      end

      def test_render_options_skips_gap_entries
        refute_match(/^:gap/, (RevealJsOptions.render_options doc))
      end

      # -- plugins --

      def test_plugins_enables_zoom_and_notes_by_default
        assert_equal 'RevealZoom, RevealNotes', (RevealJsOptions.plugins doc)
      end

      def test_plugins_can_disable_zoom_and_notes
        result = RevealJsOptions.plugins doc('revealjs_plugin_zoom' => 'disabled', 'revealjs_plugin_notes' => 'disabled')

        assert_equal '', result
      end

      def test_plugins_can_enable_search
        result = RevealJsOptions.plugins doc('revealjs_plugin_search' => 'enabled')

        assert_equal 'RevealZoom, RevealNotes, RevealSearch', result
      end

      # -- script --

      def test_script_includes_the_reveal_js_entrypoint
        result = RevealJsOptions.script doc, 'reveal.js'

        assert_includes result, '<script src="reveal.js/dist/reveal.js"></script>'
      end

      def test_script_omits_the_zoom_plugin_script_tag_when_disabled
        result = RevealJsOptions.script doc('revealjs_plugin_zoom' => 'disabled'), 'reveal.js'

        refute_includes result, 'plugin/zoom.js'
      end

      def test_script_includes_the_search_plugin_script_tag_when_enabled
        result = RevealJsOptions.script doc('revealjs_plugin_search' => 'enabled'), 'reveal.js'

        assert_includes result, 'plugin/search.js'
      end

      # -- stretch_nested_elements --

      def test_stretch_nested_elements_wires_listeners_at_the_configured_size
        result = RevealJsOptions.stretch_nested_elements doc('revealjs_width' => 1024, 'revealjs_height' => 768)

        assert_includes result, 'layoutSlideContents(1024, 768)'
      end
    end
  end
end
