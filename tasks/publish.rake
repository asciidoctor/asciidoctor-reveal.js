# frozen_string_literal: true

namespace :examples do
  # Extra assets (outside the release-*.{html,css} convention) shared by the
  # release demos and copied verbatim into public/.
  extra_release_files = ['examples/a11y-dark.css'].freeze

  desc 'Build the public/ release showcase site (landing page and release demos)'
  task :publish do
    FileUtils.rm_rf PUBLIC_DIR
    Dir.mkdir PUBLIC_DIR
    Dir.mkdir "#{PUBLIC_DIR}/reveal.js"
    FileUtils.cp_r 'node_modules/reveal.js/', PUBLIC_DIR.to_s
    FileUtils.cp_r 'examples/images/', PUBLIC_DIR.to_s

    # Discover every examples/release-<version>.html demo (and its optional
    # matching .css), copy it over, and collect the version for the landing page.
    versions = Dir.glob('examples/release-*.html').filter_map do |html|
      version = File.basename(html, '.html').delete_prefix('release-')
      FileUtils.cp html, "#{PUBLIC_DIR}/#{File.basename(html)}"
      css = "examples/release-#{version}.css"
      FileUtils.cp css, "#{PUBLIC_DIR}/#{File.basename(css)}" if File.exist?(css)
      version
    end

    extra_release_files.each { |f| FileUtils.cp f, "#{PUBLIC_DIR}/#{File.basename(f)}" }

    # List releases on the landing page, most recent version first.
    items = versions.sort_by { |v| Gem::Version.new(v) }.reverse.map do |version|
      %(          <li><a href="./release-#{version}.html">Asciidoctor reveal.js #{version}</a></li>)
    end.join("\n")

    index = File.read('tasks/index.html').sub('{{releases}}', items)
    File.write "#{PUBLIC_DIR}/index.html", index
  end
end
