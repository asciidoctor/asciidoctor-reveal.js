# frozen_string_literal: true

require 'tmpdir'
require 'rubygems/package'
require 'zlib'
require_relative 'lib/rake_assets'

EXAMPLES_DIR = 'test/fixtures/standalone'

# Extracts a .tar.gz (e.g. from `npm pack`) into dest_root using only Ruby
# stdlib/rubygems — no external `tar` binary. GNU/BSD tar disagree on several
# flags, and both misparse a Windows drive-letter path (`D:/...`) as a remote
# host spec (`host:path`), so shelling out is more trouble than it's worth
# for a one-off archive extraction.
def extract_tar_gz(tarball, dest_root)
  Zlib::GzipReader.open(tarball) do |gz|
    Gem::Package::TarReader.new(gz) do |tar|
      tar.each do |entry|
        path = File.expand_path(entry.full_name, dest_root)
        raise "refusing to extract '#{entry.full_name}' outside #{dest_root}" unless path.start_with?("#{dest_root}#{File::SEPARATOR}")

        if entry.directory?
          FileUtils.mkdir_p(path)
        elsif entry.file?
          FileUtils.mkdir_p(File.dirname(path))
          File.binwrite(path, entry.read)
        end
      end
    end
  end
end

namespace :examples do
  # The examples reference reveal.js and Font Awesome assets relatively
  # (reveal.js/dist/..., Font-Awesome-6.7.2/js/...), so a local copy must live
  # under EXAMPLES_DIR. That directory is gitignored, hence the copy from
  # node_modules on demand.
  desc "Copy reveal.js/Font Awesome assets from node_modules into #{EXAMPLES_DIR}/ (run `npm install` first)"
  task :assets do
    copy_node_module_assets(EXAMPLES_DIR, PROJECT_ROOT)
  end

  # reveal.js-plugins@4.6.0 lists `npm` itself as a dependency (upstream
  # packaging mistake), which drags in npm's entire internal tooling tree —
  # dozens of vulnerable transitive deps for a plugin package that never
  # touches any of it at runtime. Fetched via `npm pack` (downloads the
  # tarball only, no dependency resolution) instead of a normal
  # devDependency, to keep it out of package(-lock).json entirely.
  desc "Fetch reveal.js-plugins assets via `npm pack` into #{EXAMPLES_DIR}/ (bypasses its broken `npm` dependency)"
  task 'assets:reveal-js-plugins' do
    version = '4.6.0'
    dest = File.expand_path("#{EXAMPLES_DIR}/reveal.js-plugins-#{version}", PROJECT_ROOT)
    Dir.mktmpdir do |tmp|
      sh 'npm', 'pack', "reveal.js-plugins@#{version}", '--pack-destination', tmp, '--silent'
      tarball = Dir.glob(File.join(tmp, '*.tgz')).first
      raise "npm pack did not produce a tarball in #{tmp}" unless tarball

      extract_tar_gz(tarball, tmp)
      FileUtils.rm_rf(dest)
      FileUtils.cp_r(File.join(tmp, 'package'), dest)
    end
    puts "Copied reveal.js-plugins to #{dest}"
  end

  # converted slides will be put in the EXAMPLES_DIR directory
  desc "Convert every #{EXAMPLES_DIR}/*.adoc file into a browsable reveal.js presentation"
  task convert: ['load-converter', :assets, 'assets:reveal-js-plugins'] do
    Dir.glob("#{EXAMPLES_DIR}/*.adoc") do |f|
      print "Converting file #{f}... "
      out = Asciidoctor.convert_file f,
                                     safe: 'safe',
                                     backend: 'revealjs',
                                     base_dir: EXAMPLES_DIR
      if out.instance_of? Asciidoctor::Document
        puts '✔️'.green
      else
        puts '✖️'.red
      end
    end
  end

  desc 'Serve the converted examples over HTTP at http://127.0.0.1:5000'
  task serve: [:assets, 'assets:reveal-js-plugins'] do
    serve_static_dir(File.expand_path(EXAMPLES_DIR, PROJECT_ROOT))
  end
end
