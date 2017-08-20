require 'asciidoctor/doctest'
require 'thread_safe'
require 'tilt'

DocTest::RakeTasks.new do |t|
  t.output_examples :html, path: 'test/output/slim'
  t.input_examples :asciidoc, path: 'examples'
  t.converter = DocTest::HTML::Converter
  t.converter_opts = { template_dirs: 'templates/slim' }
end

# DocTest::RakeTasks.new(:doctest) do |t|
#   t.output_suite = DocTest::IO::XML
#   t.output_suite_opts = {
#     examples_path: 'test/output/slim'
#   }
#   # add extra input examples (optional)
#   t.input_suite_opts = {
#     examples_path: [ *DocTest.examples_path, 'examples' ]
#   }
#   t.converter_opts = {
#     template_dirs: 'templates/slim'
#   }
# end

# When no task specified, run test.
task :default => :doctest
