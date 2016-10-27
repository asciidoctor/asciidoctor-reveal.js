$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
if File.file?(asciidoctor_revealjs = (File.expand_path '../../lib/asciidoctor-revealjs.rb', __FILE__))
  require asciidoctor_revealjs
else
  require 'asciidoctor-revealjs'
end

require 'asciidoctor/doctest'
require 'minitest/autorun'
require 'minitest/rg'
require 'tilt'



DocTest.examples_path.unshift 'test/input'
DocTest.examples_path.unshift 'test/output'

class TestTemplates < DocTest::Test
  converter_opts template_dirs: 'templates/slim'
  # not sure about that xpath stuff
  generate_tests! DocTest::HTML::ExamplesSuite.new(paragraph_xpath: './div/p/node()')
end
