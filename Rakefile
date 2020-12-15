#!/usr/bin/env rake

require 'asciidoctor'
require 'asciidoctor/doctest'
require 'colorize'
require 'tilt'
require 'rake/testtask'

CONVERTER_FILE = 'lib/asciidoctor-revealjs/converter.rb'
JS_FILE = 'build/asciidoctor-reveal.js'
DIST_FILE = 'dist/main.js'
TEMPLATES_DIR = 'templates'
PUBLIC_DIR = 'public'

file CONVERTER_FILE => FileList["#{TEMPLATES_DIR}/*"] do
  build_converter :fast
end

namespace :build do
  desc 'Compile Slim templates and generate converter.rb'
  task :converter => 'clean' do
    # NOTE: use :pretty if you want to debug the generated code
    build_converter :fast
  end

  desc 'Compile Slim templates and generate converter.rb for Opal'
  task 'converter:opal' => 'clean' do
    build_converter :opal
  end

  desc "Transcompile to JavaScript and generate #{JS_FILE}"
  task :js => 'converter:opal' do
    require 'opal'

    builder = Opal::Builder.new(compiler_options: {
      dynamic_require_severity: :error,
    })
    builder.append_paths 'lib'
    builder.build 'asciidoctor-revealjs'

    mkdir_p [File.dirname(JS_FILE), File.dirname(DIST_FILE)]
    File.open(JS_FILE, 'w') do |file|
      template = File.read('src/asciidoctor-revealjs.tmpl.js')
      template['//OPAL-GENERATED-CODE//'] = builder.to_s
      file << template
    end
    File.binwrite "#{JS_FILE}.map", builder.source_map

    cp JS_FILE, DIST_FILE, :verbose => true
  end
end

task :build => 'build:converter'

task :clean do
  rm_rf CONVERTER_FILE
  rm_rf PUBLIC_DIR
end

def build_converter(mode = :pretty)
  #require 'asciidoctor-templates-compiler'
  require_relative 'lib/asciidoctor-templates-compiler'
  require 'slim-htag'

  generator = if mode == :opal
    Temple::Generators::ArrayBuffer.new(freeze_static: false)
  else
    Temple::Generators::StringBuffer
  end

  File.open(CONVERTER_FILE, 'w') do |file|
    puts "Generating #{file.path} (mode: #{mode})."

    Asciidoctor::TemplatesCompiler::RevealjsSlim.compile_converter(
      templates_dir: TEMPLATES_DIR,
      class_name: 'Asciidoctor::Revealjs::Converter',
      register_for: ['revealjs', 'reveal.js'],
      backend_info: {
        basebackend: 'html',
        outfilesuffix: '.html',
        filetype: 'html',
        supports_templates: true
      },
      delegate_backend: 'html5',
      engine_opts: {
        generator: generator,
      },
      pretty: (mode == :pretty),
      output: file
    )
  end
end

DocTest::RakeTasks.new do |t|
  t.output_examples :html, path: 'test/doctest'
  t.input_examples :asciidoc, path: [ *DocTest.examples_path, 'examples' ]
  t.converter = DocTest::HTML::Converter
  t.converter_opts = { backend_name: 'revealjs' }
end

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/asciidoctor-revealjs/*_test.rb']
  t.warning = false
end

task 'prepare-converter' do
  # Run as an external process to ensure that it will not affect tests
  # environment with extra loaded modules (especially slim).
  `bundle exec rake #{CONVERTER_FILE}`

  require_relative 'lib/asciidoctor-revealjs'
end

namespace :examples do
  desc 'Converts all the test slides into fully working examples that you can look in a browser'
  # converted slides will be put in examples/ directory
  task :convert => 'build:converter' do
    require 'slim-htag'
    require_relative 'lib/asciidoctor-revealjs'
    Dir.glob('examples/*.adoc') do |_file|
      print "Converting file #{_file}... "
      out = Asciidoctor.convert_file _file,
        :safe => 'safe',
        :backend => 'revealjs',
        :base_dir => 'examples'
      if out.instance_of? Asciidoctor::Document
        puts "✔️".green
      else
        puts "✖️".red
      end
    end
  end

  task :serve do
    puts "View rendered examples at: http://127.0.0.1:5000/"
    puts "Exit with Ctrl-C"
    Dir.chdir('examples') do
      `ruby -run -e httpd . -p 5000 -b 127.0.0.1`
    end
  end

  task :publish do
    FileUtils.rm_rf PUBLIC_DIR
    Dir.mkdir PUBLIC_DIR
    Dir.mkdir "#{PUBLIC_DIR}/reveal.js"
    FileUtils.cp 'src/index.html', "#{PUBLIC_DIR}/index.html"
    FileUtils.cp_r 'node_modules/reveal.js/', "#{PUBLIC_DIR}"
    FileUtils.cp_r 'examples/images/', "#{PUBLIC_DIR}"
    FileUtils.cp 'examples/release-4.0.html', "#{PUBLIC_DIR}/release-4.0.html"
    FileUtils.cp 'examples/release-4.0.css', "#{PUBLIC_DIR}/release-4.0.css"
    FileUtils.cp 'examples/release-4.1.html', "#{PUBLIC_DIR}/release-4.1.html"
    FileUtils.cp 'examples/release-4.1.css', "#{PUBLIC_DIR}/release-4.1.css"
    FileUtils.cp 'examples/a11y-dark.css', "#{PUBLIC_DIR}/a11y-dark.css"
  end
end

task 'test' => 'doctest'
task 'doctest:test' => 'prepare-converter'
task 'doctest:generate' => 'prepare-converter'
# When no task specified, run test.
task :default => :test
