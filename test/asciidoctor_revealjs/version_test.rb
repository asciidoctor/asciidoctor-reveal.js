# frozen_string_literal: true

require_relative '../test_helper'

module Asciidoctor
  module Revealjs
    class VersionTest < Minitest::Test
      def test_that_it_has_a_version_number
        refute_nil ::Asciidoctor::Revealjs::VERSION
      end
    end
  end
end
