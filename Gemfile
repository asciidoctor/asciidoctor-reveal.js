source 'https://rubygems.org'

# Specify your gem's dependencies in asciidoctor-revealjs.gemspec
gemspec

group :development do
  # Asciidoctor.js 2.0.0 requires an unreleased Opal 0.11.99.dev (d136ea8)
  gem 'opal', :git => 'https://github.com/opal/opal.git', :ref => 'd136ea8'
  # Asciidoctor Doctest based on Nokogiri 1.13
  gem 'asciidoctor-doctest', git: 'https://github.com/ggrossetie/asciidoctor-doctest.git', :ref => 'c2cba5240'
end
