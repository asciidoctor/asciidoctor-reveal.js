require 'asciidoctor'
require 'json'

if Gem::Version.new(Asciidoctor::VERSION) <= Gem::Version.new('1.5.3')
  fail 'asciidoctor: FAILED: reveal.js backend needs Asciidoctor >=1.5.4!'
end

unless defined? Slim::Include
  fail 'asciidoctor: FAILED: reveal.js backend needs Slim >= 2.1.0!'
end

# This module gets mixed in to every node (the context of the template) at the
# time the node is being converted. The properties and methods in this module
# effectively become direct members of the template.
module Slim::Helpers

  # Following constants from Bespoke back-end
  #--
  EOL = %(\n)
  SliceHintRx = /  +/
  #--

  # Following functions are taken from Bespoke back-end
  #--
  def pluck selector = {}, &block
    quantity = (selector.delete :quantity).to_i
    if blocks?
      unless (result = find_by selector, &block).empty?
        result = result[0..(quantity - 1)] if quantity > 0
        result.each {|b| b.set_attr 'skip-option', '' }
      end
    else
      result = []
    end
    quantity == 1 ? result[0] : result
  end

  def pluck_first selector = {}, &block
    pluck selector.merge(quantity: 1), &block
  end

  def partition_title str
    ::Asciidoctor::Document::Title.new str, separator: (@document.attr 'title-separator')
  end

  # QUESTION should we wrap in span.line if active but delimiter is not present?
  # TODO alternate terms for "slice" - part(ition), chunk, segment, split, break
  def slice_text str, active = nil
    if (active || (active.nil? && (option? :slice))) && (str.include? '  ')
      (str.split SliceHintRx).map {|line| %(<span class="line">#{line}</span>) }.join EOL
    else
      str
    end
  end
  #--
end

# More custom functions can be added in another namespace if required
#module Helpers
#end
