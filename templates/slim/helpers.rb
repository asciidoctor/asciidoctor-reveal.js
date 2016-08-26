require 'asciidoctor'
require 'json'

if Gem::Version.new(Asciidoctor::VERSION) <= Gem::Version.new('1.5.3')
  fail 'asciidoctor: FAILED: reveal.js backend needs Asciidoctor >=1.5.4!'
end

unless defined? Slim::Include
  fail 'asciidoctor: FAILED: reveal.js backend needs Slim >= 2.1.0!'
end

# Add custom functions to this module that you want to use in your Slim
# templates. Within the template you must namespace the function
# (unless someone can show me how to include them in the evaluation context).
# You can change the namespace to whatever you want.
module Helpers
  #def self.a_helper_function
  #end
end
