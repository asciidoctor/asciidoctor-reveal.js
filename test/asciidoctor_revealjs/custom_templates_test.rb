# frozen_string_literal: true

require_relative '../test_helper'

module Asciidoctor
  module Revealjs
    class CustomTemplatesTest < Minitest::Test
      def test_that_templates_can_be_overridden_using_template_dirs_option
        html = ::Asciidoctor.convert('hello world', { template_dirs: 'test/asciidoctor_revealjs/fixtures/templates', template_engine: 'slim' })

        assert_equal '<p class="paragraph">hello world</p>', html
      end
    end
  end
end
