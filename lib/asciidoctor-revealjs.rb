if RUBY_ENGINE == 'opal'
  require 'asciidoctor-revealjs/stylesheet'
  require 'asciidoctor-revealjs/reveal_js_options'
  require 'asciidoctor-revealjs/converter'
  require 'asciidoctor-revealjs/version'
  require 'asciidoctor-revealjs/highlightjs'
else
  require 'asciidoctor' unless defined? Asciidoctor::Converter
  require_relative 'asciidoctor-revealjs/stylesheet'
  require_relative 'asciidoctor-revealjs/reveal_js_options'
  require_relative 'asciidoctor-revealjs/converter'
  require_relative 'asciidoctor-revealjs/version'
  require_relative 'asciidoctor-revealjs/highlightjs'
end
