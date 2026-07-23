# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
if File.file?(asciidoctor_revealjs = (File.expand_path '../lib/asciidoctor_revealjs.rb', __dir__))
  require asciidoctor_revealjs
else
  require 'asciidoctor_revealjs'
end

require 'asciidoctor/doctest'
require 'minitest/autorun'
