# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in asciidoctor-revealjs.gemspec
gemspec

group :development do
  gem 'minitest', '~> 5.25'
  gem 'rake', '~> 13.4.0'
  gem 'rubocop', '~> 1.86', require: false
  gem 'rubocop-minitest', '~> 0.39.1'
  gem 'rubocop-rake', '~> 0.7.1'
  if RUBY_ENGINE != 'jruby'
    gem 'irb'
    gem 'pry', '~> 0.12.0'
    gem 'pry-byebug'
    gem 'pygments.rb'
  end
  gem 'colorize'
  # slim is only used by the custom-templates test, which checks that users can
  # still override individual templates with their own Slim files.
  gem 'rouge'
  gem 'slim', '~> 3.0.6'
end
