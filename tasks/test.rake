# frozen_string_literal: true

# Loads the converter so its backend is registered with Asciidoctor.
desc 'Register the reveal.js converter backend with Asciidoctor'
task 'load-converter' do
  require_relative '../lib/asciidoctor_revealjs'
end

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/asciidoctor_revealjs/*_test.rb']
  t.warning = false
end

desc 'Run the full test suite (unit tests and asciidoc-testkit fixtures)'
task 'test' => 'testkit:test'
