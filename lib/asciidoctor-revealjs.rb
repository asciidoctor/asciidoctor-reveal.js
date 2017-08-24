if RUBY_ENGINE == 'opal'
  require 'asciidoctor-revealjs/converter'
else
  require 'asciidoctor' unless defined? Asciidoctor::Converter
  require_relative 'asciidoctor-revealjs/converter'
  require_relative 'asciidoctor-revealjs/version'
end
