# frozen_string_literal: true

# Replaces the old `doctest:*` tasks (asciidoctor-doctest gem) with
# asciidoc-testkit (https://github.com/ggrossetie/asciidoc-testkit), the
# asciidoc-testkit-cli npm package (run `npm install` first).
#
# Two separate invocations, not one, because asciidoc-testkit runs a single
# fixed command for every case in a given invocation (no per-case converter
# flags) — and these two groups of families need different converter flags:
#
# - the 37 generic AsciiDoc-construct families asciidoc-testkit ships as its
#   bundled corpus (test/fixtures/<family>/<case>.html) are single-construct
#   snippets, converted embedded (`-e`);
# - the "revealjs" and "revealjs-examples" families
#   (test/fixtures-revealjs/<family>/<case>.html) are full reveal.js
#   presentations — converted standalone (no `-e`), so the title slide and
#   the `<div class="slides">` wrapper are present, then narrowed down to the
#   relevant fragment via each case's `<name>.config.json` sidecar (a
#   `select` CSS selector list — see asciidoc-testkit's fragment-extraction
#   docs). "revealjs" is test-only: cases that only exist to pin down a
#   specific behavior (docinfo, slide numbers, syntax highlighters, ...),
#   with no independent showcase value, living directly under
#   test/fixtures-extra/revealjs/, not in examples/. "revealjs-examples" is
#   *also* a real, browsable example (background-color, grid-layout, video,
#   ...), supplied via --fixtures from test/fixtures-extra/revealjs-examples,
#   a symlink to examples/ — that directory is also used by the showcase
#   (tasks/examples.rake, tasks/publish.rake) and the JS/Ruby parity test
#   (js/test/examples.test.js), so it's exposed as-is rather than duplicated.
#   A file in examples/ with no matching
#   test/fixtures-revealjs/revealjs-examples/<name>.html is simply skipped —
#   that's how a pure showcase demo (release-*, auto-animate, ...) opts out.
#   Each invocation's --expected root only holds the subdirectories it's
#   responsible for, so the other invocation's families are silently skipped
#   there rather than run with the wrong flag.
#
# Both invocations run through the input file itself (the {input} token, not
# stdin), so a case that resolves file-relative references — docinfo files,
# imagesdir, include:: — from its own directory sees exactly what it would
# for a direct, non-testkit invocation.

RUBY_CONVERTER = %w[bundle exec asciidoctor -r ./lib/asciidoctor_revealjs -b revealjs -S safe -o -].freeze
JS_CONVERTER = %w[node js/bin/asciidoctor-revealjs -b revealjs -S safe -o -].freeze

def testkit_cli
  path = File.expand_path('../node_modules/.bin/asciidoc-testkit', __dir__)
  abort "asciidoc-testkit-cli not found at #{path}; run `npm install` first" unless File.file?(path)
  path
end

def run_testkit(expected:, converter:, converter_args: [], fixtures: nil, extra_args: [])
  sh testkit_cli, 'run',
     '--expected', expected,
     '--extension', 'html',
     *(fixtures ? ['--fixtures', fixtures] : []),
     *extra_args,
     '--', *converter, *converter_args, '{input}'
end

def run_testkit_generic(converter, *extra_args)
  run_testkit(expected: 'test/fixtures', converter: converter, converter_args: ['-e'], extra_args: extra_args)
end

def run_testkit_revealjs(converter, *extra_args)
  run_testkit(
    expected: 'test/fixtures-revealjs',
    converter: converter,
    fixtures: 'test/fixtures-extra',
    extra_args: extra_args
  )
end

desc 'Run the asciidoc-testkit fixtures against the Ruby converter'
task 'testkit:test' => 'load-converter' do
  run_testkit_generic RUBY_CONVERTER
  run_testkit_revealjs RUBY_CONVERTER
end

desc 'Regenerate the asciidoc-testkit expected fixtures from the current converter'
task 'testkit:update' => 'load-converter' do
  run_testkit_generic RUBY_CONVERTER, '--update'
  run_testkit_revealjs RUBY_CONVERTER, '--update'
end

desc 'Run the asciidoc-testkit fixtures against the JS converter (parity check, no --update: the Ruby converter is the reference)'
task 'testkit:test:js' do
  run_testkit_generic JS_CONVERTER
  run_testkit_revealjs JS_CONVERTER
end
