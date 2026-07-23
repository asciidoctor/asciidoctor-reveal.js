# frozen_string_literal: true

# Loads the converter so its backend is registered with Asciidoctor.
desc 'Register the reveal.js converter backend with Asciidoctor'
task 'load-converter' do
  require_relative '../lib/asciidoctor_revealjs'
end

Rake::TestTask.new('test:unit') do |t|
  t.test_files = FileList['test/asciidoctor_revealjs/*_test.rb']
  t.warning = false
end

# JRuby/TruffleRuby CI legs run `test:unit` only, skipping the asciidoc-testkit
# corpus: those legs exist to catch Ruby-implementation compat bugs (e.g. a
# JRuby/TruffleRuby-specific crash), not to re-validate fixture content, which
# the CRuby legs already do exhaustively — and the corpus's ~300 sequential
# `bundle exec` spawns (asciidoc-testkit has no persistent-worker mode yet)
# multiply JRuby/TruffleRuby's JVM startup cost into a 10+ minute CI job.
desc 'Run the full test suite (unit tests and asciidoc-testkit fixtures)'
task 'test' => %w[test:unit testkit:test]
