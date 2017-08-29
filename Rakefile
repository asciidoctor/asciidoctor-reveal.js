require 'asciidoctor'
require 'asciidoctor/doctest'
require 'colorize'
require 'thread_safe'
require 'tilt'

DocTest::RakeTasks.new do |t|
  t.output_examples :html, path: 'test/output/slim'
  t.input_examples :asciidoc, path: [ *DocTest.examples_path, 'examples' ]
  t.converter = DocTest::HTML::Converter
  t.converter_opts = { template_dirs: 'templates/slim' }
end

namespace :examples do
  desc 'Converts all the test slides into fully working examples that you can look in a browser'
  # converted slides will be put in examples/ directory
  task :convert do
    Dir.glob('examples/*.adoc') do |_file|
      print "Converting file #{_file}... "
      out = Asciidoctor.convert_file _file,
        :safe => 'safe',
        :backend => 'revealjs',
        :base_dir => 'examples',
        :template_dir => 'templates/slim'
      if out.instance_of? Asciidoctor::Document
        puts "✔️".green
      else
        puts "✖️".red
      end
    end
  end
end

# When no task specified, run test.
task :default => :doctest
