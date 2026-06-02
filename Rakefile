#!/usr/bin/env rake
# frozen_string_literal: true

require 'asciidoctor'
require 'asciidoctor/doctest'
require 'colorize'
require 'rake/testtask'

PUBLIC_DIR = 'public'

desc 'Clean public directory'
task :clean do
  rm_rf PUBLIC_DIR
end

# Loads the converter so its backend is registered with Asciidoctor.
desc 'Load converter'
task 'load-converter' do
  require_relative 'lib/asciidoctor_revealjs'
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

namespace :examples do
  # converted slides will be put in examples/ directory
  desc 'Converts all the test slides into fully working examples that you can look in a browser'
  task convert: 'load-converter' do
    Dir.glob('examples/*.adoc') do |f|
      print "Converting file #{f}... "
      out = Asciidoctor.convert_file f,
                                     safe: 'safe',
                                     backend: 'revealjs',
                                     base_dir: 'examples'
      if out.instance_of? Asciidoctor::Document
        puts '✔️'.green
      else
        puts '✖️'.red
      end
    end
  end

  desc 'Serve'
  task :serve do
    puts 'View rendered examples at: http://127.0.0.1:5000/'
    puts 'Exit with Ctrl-C'
    Dir.chdir('examples') do
      `ruby -run -e httpd . -p 5000 -b 127.0.0.1`
    end
  end

  desc 'Publish'
  task :publish do
    FileUtils.rm_rf PUBLIC_DIR
    Dir.mkdir PUBLIC_DIR
    Dir.mkdir "#{PUBLIC_DIR}/reveal.js"
    FileUtils.cp 'src/index.html', "#{PUBLIC_DIR}/index.html"
    FileUtils.cp_r 'node_modules/reveal.js/', PUBLIC_DIR.to_s
    FileUtils.cp_r 'examples/images/', PUBLIC_DIR.to_s
    FileUtils.cp 'examples/release-4.0.html', "#{PUBLIC_DIR}/release-4.0.html"
    FileUtils.cp 'examples/release-4.0.css', "#{PUBLIC_DIR}/release-4.0.css"
    FileUtils.cp 'examples/release-4.1.html', "#{PUBLIC_DIR}/release-4.1.html"
    FileUtils.cp 'examples/release-4.1.css', "#{PUBLIC_DIR}/release-4.1.css"
    FileUtils.cp 'examples/a11y-dark.css', "#{PUBLIC_DIR}/a11y-dark.css"
    FileUtils.cp 'examples/release-5.1.html', "#{PUBLIC_DIR}/release-5.1.html"
    FileUtils.cp 'examples/release-5.1.css', "#{PUBLIC_DIR}/release-5.1.css"
    FileUtils.cp 'examples/release-5.2.html', "#{PUBLIC_DIR}/release-5.2.html"
  end
end

desc 'Run all tests'
task 'test' => 'doctest'

desc 'Test using doctest'
task 'doctest:test' => 'load-converter'

desc 'Generate doctest'
task 'doctest:generate' => 'load-converter'

desc 'No task specified, run tes'
task default: :test
