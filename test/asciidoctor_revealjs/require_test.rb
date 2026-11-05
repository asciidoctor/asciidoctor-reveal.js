# frozen_string_literal: true

require_relative '../test_helper'
require 'open3'
require 'rbconfig'

module Asciidoctor
  module Revealjs
    class RequireTest < Minitest::Test
      LIB_DIR = File.expand_path '../../lib', __dir__

      { 'hyphenated_gem_name' => 'asciidoctor-revealjs', 'underscored_name' => 'asciidoctor_revealjs' }.each do |name, feature|
        define_method :"test_require_#{name}_registers_the_revealjs_converter" do
          script = <<~RUBY
            require '#{feature}'
            print Asciidoctor::Converter.for('revealjs')
          RUBY
          out, err, status = Open3.capture3 RbConfig.ruby, '-I', LIB_DIR, '-e', script

          assert_predicate status, :success?, "require '#{feature}' failed: #{err}"
          assert_equal 'Asciidoctor::Revealjs::Converter', out
        end
      end
    end
  end
end
