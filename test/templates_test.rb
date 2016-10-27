require 'test_helper'

class TestTemplates < DocTest::Test
  converter_opts template_dirs: 'templates/slim'
  generate_tests! DocTest::HTML::ExamplesSuite
end
