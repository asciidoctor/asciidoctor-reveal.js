# frozen_string_literal: true

require File.expand_path 'lib/asciidoctor_revealjs/version', __dir__
require 'open3'

Gem::Specification.new do |s|
  s.required_ruby_version = '>= 2.7'
  s.name = 'asciidoctor-revealjs'
  s.version = Asciidoctor::Revealjs::VERSION
  s.authors = ['Olivier Bilodeau']
  s.email = ['olivier@bottomlesspit.org']
  s.homepage = 'https://github.com/asciidoctor/asciidoctor-reveal.js'
  s.summary = 'A reveal.js converter for Asciidoctor. Write your slides in AsciiDoc!'
  s.description = 'Converts AsciiDoc documents into HTML5 presentations designed to be executed by the reveal.js presentation framework.'
  s.license = 'MIT'

  files = begin
    if (result = Open3.popen3('git ls-files -z') { |_, out| out.read }.split %(\0)).empty?
      Dir['**/*']
    else
      result
    end
  rescue StandardError
    Dir['**/*']
  end
  s.files = files.grep %r{^(?:(?:data|examples|lib)/.+|Gemfile|Rakefile|(?:CHANGELOG|LICENSE|README)\.adoc|#{s.name}\.gemspec)$}

  s.executables = ['asciidoctor-revealjs']
  s.extra_rdoc_files = Dir['README.adoc', 'LICENSE.adoc', 'HACKING.adoc']
  s.require_paths = ['lib']

  s.add_dependency 'asciidoctor', ['>= 2.0.0', '< 3.0.0']
  s.metadata['rubygems_mfa_required'] = 'true'
end
