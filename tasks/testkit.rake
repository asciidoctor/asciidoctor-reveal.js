# frozen_string_literal: true

# Experimental replacement for the `doctest:*` tasks in tasks/test.rake,
# using asciidoc-testkit (https://github.com/ggrossetie/asciidoc-testkit,
# not published yet — expected as a sibling checkout of the main repo, not
# of whatever worktree this happens to run from) instead of the
# asciidoctor-doctest gem.
#
# Only covers the 37 generic AsciiDoc-construct families asciidoc-testkit
# ships as its shared input corpus (test/fixtures/<family>/<case>.html,
# split from the equivalent test/doctest/<family>.html). The 56 reveal.js-
# specific fixtures in test/doctest (background-color, custom-layout,
# fragments, ...) are full presentations sourced from examples/*.adoc, a
# different shape asciidoc-testkit's corpus doesn't cover — they still run
# only through the existing `doctest:test` task for now.

# The main repo root, even when running from a worktree nested arbitrarily
# deep (e.g. .claude/worktrees/<branch>) — asciidoc-testkit is expected next
# to *that*, not next to the current working directory.
def main_repo_root
  git_common_dir = `git rev-parse --path-format=absolute --git-common-dir`.strip
  File.dirname(git_common_dir)
end

def testkit_cli
  path = File.expand_path('../asciidoc-testkit/packages/cli/src/cli.js', main_repo_root)
  abort "asciidoc-testkit not found at #{path} (expected as a sibling checkout of #{main_repo_root})" unless File.file?(path)
  path
end

def run_testkit(*extra_args)
  sh 'node', testkit_cli, 'run',
     '--expected', 'test/fixtures',
     '--extension', 'html',
     *extra_args,
     '--', 'bundle', 'exec', 'asciidoctor',
     '-r', './lib/asciidoctor_revealjs', '-b', 'revealjs', '-S', 'safe', '-e', '-o', '-', '-'
end

desc 'Run the asciidoc-testkit fixtures against the Ruby converter (experimental)'
task 'testkit:test' => 'load-converter' do
  run_testkit
end

desc 'Regenerate the asciidoc-testkit expected fixtures from the current converter (experimental)'
task 'testkit:update' => 'load-converter' do
  run_testkit '--update'
end