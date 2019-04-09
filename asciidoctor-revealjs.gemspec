# -*- encoding: utf-8 -*-
require File.expand_path '../lib/asciidoctor-revealjs/version', __FILE__
require 'open3'

Gem::Specification.new do |s|
  s.name = 'asciidoctor-revealjs'
  s.version = Asciidoctor::Revealjs::VERSION
  s.authors = ['Olivier Bilodeau']
  s.email = ['olivier@bottomlesspit.org']
  s.homepage = 'https://github.com/asciidoctor/asciidoctor-reveal.js'
  s.summary = 'Converts AsciiDoc to HTML for a Reveal.js presentation'
  s.description = 'Reveal.JS back-end for Asciidoctor and Asciidoctor.js. Write slides in AsciiDoc!'
  s.license = 'MIT'

  files = begin
    if (result = Open3.popen3('git ls-files -z') {|_, out| out.read }.split %(\0)).empty?
      Dir['**/*']
    else
      # converter.rb is built locally before packaging but ignored by git. Adding manually.
      result + ['lib/asciidoctor-revealjs/converter.rb']
    end
  rescue
    Dir['**/*']
  end
  # TODO should we still package template files now that they are built into ruby?
  s.files = files.grep %r/^(?:(?:examples|lib|templates)\/.+|Gemfile|Rakefile|(?:CHANGELOG|LICENSE|README)\.adoc|#{s.name}\.gemspec)$/

  s.executables = ['asciidoctor-revealjs']
  s.extra_rdoc_files = Dir['README.adoc', 'LICENSE.adoc', 'HACKING.adoc']
  s.require_paths = ['lib']

  s.add_runtime_dependency 'asciidoctor', ['>= 1.5.6', '< 3.0.0']
  s.add_runtime_dependency 'thread_safe', '~> 0.3.5'
  s.add_runtime_dependency 'concurrent-ruby', '~> 1.0'

  s.add_development_dependency 'rake', '~> 10.4.2'
  s.add_development_dependency 'asciidoctor-doctest', '= 2.0.0.beta.5'
  s.add_development_dependency 'pry', '~> 0.10.4'
  if RUBY_ENGINE != 'jruby'
    s.add_development_dependency 'pry-byebug'
  end
  s.add_development_dependency 'colorize'
  s.add_development_dependency 'asciidoctor-templates-compiler', '~> 0.4.2'
  s.add_development_dependency 'slim', '~> 3.0.6'
  s.add_development_dependency 'slim-htag', '~> 0.1.0'
  # Overriden in Gemfile and Gemfile.upstream for now
  #s.add_development_dependency 'opal', '~> 0.11.1'
end
