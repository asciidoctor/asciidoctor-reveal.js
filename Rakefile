require 'asciidoctor'
require 'asciidoctor/doctest'
require 'thread_safe'
require 'tilt'

DocTest::RakeTasks.new do |t|
  t.output_examples :html, path: 'test/output/slim'
  t.input_examples :asciidoc, path: [ *DocTest.examples_path, 'examples' ]
  t.converter = DocTest::HTML::Converter
  t.converter_opts = { template_dirs: 'templates/slim' }
end

desc 'Renders all the test slides into fully working examples that you can look in a browser'
# rendered slides will be put in examples/ directory
task :render do
#    Asciidoctor.convert_file 'data-background-newstyle.adoc',
#        :backend => 'revealjs',
#        :base_dir => 'examples'
##        :template_dir => 'templates/slim'
	system "bundle exec asciidoctor-revealjs data-background-oldstyle.adoc", :chdir => 'examples'
end

# When no task specified, run test.
task :default => :doctest
