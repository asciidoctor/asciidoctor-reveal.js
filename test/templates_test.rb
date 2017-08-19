require 'test_helper'

DocTest.examples_path.unshift 'examples'
DocTest.examples_path.unshift 'test/output/slim'

class TestTemplates < DocTest::Test
  converter_opts template_dirs: 'templates/slim'
  generate_tests! DocTest::HTML::ExamplesSuite.new(paragraph_xpath: './div/p/node()')
end
