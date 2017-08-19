require 'asciidoctor/doctest'
require "bundler/gem_tasks"
require 'rake/testtask'
require 'thread_safe'
require 'tilt'

Rake::TestTask.new(:test) do |task|
  task.description = 'Run tests for templates'
  task.pattern = 'test/templates_test.rb'
  task.libs << 'test'
  task.test_files = FileList['test/**/*_test.rb']
end

DocTest::GeneratorTask.new(:generate) do |task|
  task.output_suite = DocTest::HTML::ExamplesSuite.new(
    examples_path: 'test/output/slim',
    paragraph_xpath: './div/p/node()'
  )
  task.converter_opts[:template_dirs] = 'templates/slim'
  task.examples_path.unshift 'examples'
end

# When no task specified, run test.
task :default => :test
