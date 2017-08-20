require 'asciidoctor/doctest'
require 'thread_safe'
require 'tilt'

DocTest::RakeTasks.new do |t|
  t.output_examples :html, path: 'test/output/slim'
  t.input_examples :asciidoc, path: [ *DocTest.examples_path, 'examples' ]
  t.converter = DocTest::HTML::Converter
  t.converter_opts = { template_dirs: 'templates/slim' }
end

# TODO add a rake task to render fully working examples to look at them in a browser

# When no task specified, run test.
task :default => :doctest
