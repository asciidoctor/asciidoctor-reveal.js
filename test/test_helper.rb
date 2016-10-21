require 'asciidoctor/doctest'
require 'minitest/autorun'
require 'minitest/rg'
require 'tilt'

DocTest.examples_path.unshift 'test/examples/asciidoc'
DocTest.examples_path.unshift 'test/examples/revealjs'

class TestTemplates < DocTest::Test
  converter_opts template_dirs: 'templates/slim'
  generate_tests! DocTest::HTML::ExamplesSuite.new(paragraph_xpath: './div/p/node()')
end
