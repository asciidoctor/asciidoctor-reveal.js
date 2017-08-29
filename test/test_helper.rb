$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
if File.file?(asciidoctor_revealjs = (File.expand_path '../../lib/asciidoctor-revealjs.rb', __FILE__))
  require asciidoctor_revealjs
else
  require 'asciidoctor-revealjs'
end

require 'asciidoctor/doctest'
require 'minitest/autorun'
require 'minitest/rg'
require 'tilt'
