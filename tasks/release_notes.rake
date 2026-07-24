# frozen_string_literal: true

require_relative 'lib/rake_assets'

RELEASE_NOTES_DIR = 'release-notes'

namespace :release_notes do
  # The release notes reference reveal.js and Font Awesome assets relatively
  # (reveal.js/dist/..., Font-Awesome-6.7.2/js/...), so a local copy must live
  # under RELEASE_NOTES_DIR. That directory is gitignored, hence the copy from
  # node_modules on demand.
  desc "Copy reveal.js/Font Awesome assets from node_modules into #{RELEASE_NOTES_DIR}/ (run `npm install` first)"
  task :assets do
    copy_node_module_assets(RELEASE_NOTES_DIR, PROJECT_ROOT)
  end

  # converted slides will be put in the RELEASE_NOTES_DIR directory
  desc "Convert every #{RELEASE_NOTES_DIR}/*.adoc file into a browsable reveal.js presentation"
  task convert: ['load-converter', :assets] do
    Dir.glob("#{RELEASE_NOTES_DIR}/*.adoc") do |f|
      print "Converting file #{f}... "
      out = Asciidoctor.convert_file f,
                                     safe: 'safe',
                                     backend: 'revealjs',
                                     base_dir: RELEASE_NOTES_DIR
      if out.instance_of? Asciidoctor::Document
        puts '✔️'.green
      else
        puts '✖️'.red
      end
    end
  end

  desc 'Serve the converted release notes over HTTP at http://127.0.0.1:5001'
  task serve: [:assets] do
    serve_static_dir(File.expand_path(RELEASE_NOTES_DIR, PROJECT_ROOT), port: 5001)
  end
end
