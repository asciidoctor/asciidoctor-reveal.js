#!/usr/bin/env rake
# frozen_string_literal: true

require 'asciidoctor'
require 'asciidoctor/doctest'
require 'colorize'
require 'rake/testtask'

PROJECT_ROOT = __dir__
PUBLIC_DIR = 'public'

# Task definitions are split across tasks/*.rake to keep this file small.
Dir.glob('tasks/*.rake').sort.each { |rakefile| import rakefile }

desc 'Remove the generated public/ site directory'
task :clean do
  rm_rf PUBLIC_DIR
end

desc 'Default task: run the full test suite'
task default: :test
