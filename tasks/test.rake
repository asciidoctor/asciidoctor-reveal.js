# frozen_string_literal: true

# Loads the converter so its backend is registered with Asciidoctor.
desc 'Register the reveal.js converter backend with Asciidoctor'
task 'load-converter' do
  require_relative '../lib/asciidoctor_revealjs'
end

DocTest::RakeTasks.new do |t|
  t.output_examples :html, path: 'test/doctest'
  t.input_examples :asciidoc, path: [*DocTest.examples_path, 'examples']
  t.converter = DocTest::HTML::Converter
  t.converter_opts = { backend_name: 'revealjs' }
end

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/asciidoctor_revealjs/*_test.rb']
  t.warning = false
end

desc 'Run the full test suite (unit tests and doctest examples)'
task 'test' => 'doctest'

desc 'Run integration tests for the reveal.js converter'
task 'doctest:test' => 'load-converter'
desc 'Generate test examples for the reveal.js converter'
task 'doctest:generate' => 'load-converter'
