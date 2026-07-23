#!/usr/bin/env rake
# frozen_string_literal: true

require 'bundler/gem_tasks'

# Drop `release:source_control_push` from `rake release`: the git tag is already
# created and pushed by the release workflow's prepare step, so `rake release`
# (invoked by rubygems/release-gem) should only build and push the gem.
release_task = Rake::Task['release']
release_task.clear_prerequisites
release_task.clear_comments
desc 'Build and push the gem to rubygems.org (the git tag is created by the release workflow)'
task 'release' => %w[build release:guard_clean release:rubygem_push]

require 'asciidoctor'
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
