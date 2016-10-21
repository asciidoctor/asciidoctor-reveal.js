require 'test_helper'

class TestTemplates < DocTest::Test
  converter_opts template_dirs: 'data/templates'
  generate_tests! DocTest::HTML::ExamplesSuite
end
