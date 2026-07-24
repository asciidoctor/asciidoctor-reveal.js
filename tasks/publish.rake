# frozen_string_literal: true

namespace :release_notes do
  # Extra assets (outside the release-*.{html,css} convention) shared by the
  # release demos and copied verbatim into public/.
  #
  # Hardcoded rather than reusing the RELEASE_NOTES_DIR constant from
  # tasks/release_notes.rake: tasks/*.rake files are imported in alphabetical
  # order (see Rakefile), and this file loads before that one.
  extra_release_files = ['release-notes/a11y-dark.css'].freeze

  # Short highlights shown on the landing page, keyed by release version.
  # Add a new entry whenever a release-<version>.adoc demo is introduced; a
  # version without an entry still gets a card, just without the bullet list.
  release_highlights = {
    '6.0' => ['Image lightbox', 'Full-screen website preview overlay', 'Powered by reveal.js 6.0'],
    '5.2' => ['Step-by-step callout lists', 'Synchronised step-by-step syntax highlighting'],
    '5.1' => ['Gradient slide backgrounds', 'Typesetting libraries (LaTeX math)'],
    '4.1' => ['Steps and incremental reveal', 'Footnotes', 'Custom data attributes', 'Font Awesome icon sets', 'Built-in text alignments'],
    '4.0' => ['Automatic source code highlighting', 'Easy grid layouts', 'Font Awesome integration', 'Background videos and includes']
  }.freeze

  desc 'Build the public/ release showcase site (landing page and release demos)'
  task :publish do
    FileUtils.rm_rf PUBLIC_DIR
    Dir.mkdir PUBLIC_DIR
    Dir.mkdir "#{PUBLIC_DIR}/reveal.js"
    FileUtils.cp_r 'node_modules/reveal.js/', PUBLIC_DIR.to_s
    FileUtils.cp_r 'release-notes/images/', PUBLIC_DIR.to_s

    # Discover every release-notes/release-<version>.html demo (and its
    # optional matching .css), copy it over, and collect the version for the
    # landing page.
    versions = Dir.glob('release-notes/release-*.html').filter_map do |html|
      version = File.basename(html, '.html').delete_prefix('release-')
      FileUtils.cp html, "#{PUBLIC_DIR}/#{File.basename(html)}"
      css = "release-notes/release-#{version}.css"
      FileUtils.cp css, "#{PUBLIC_DIR}/#{File.basename(css)}" if File.exist?(css)
      version
    end

    extra_release_files.each { |f| FileUtils.cp f, "#{PUBLIC_DIR}/#{File.basename(f)}" }

    # Render one card per release on the landing page, most recent version
    # first, tagging the latest release and listing its curated highlights.
    sorted = versions.sort_by { |v| Gem::Version.new(v) }.reverse
    latest = sorted.first
    items = sorted.map do |version|
      is_latest = version == latest
      card_class = is_latest ? 'release-card release-card--latest' : 'release-card'
      lines = ['        <div class="column is-half">']
      lines << %(          <article class="#{card_class}">)
      lines << '            <div class="release-card__head">'
      lines << %(              <h2 class="release-card__title">Asciidoctor reveal.js #{version}</h2>)
      lines << '              <span class="release-card__tag">Latest</span>' if is_latest
      lines << '            </div>'
      highlights = Array(release_highlights[version])
      unless highlights.empty?
        lines << '            <ul class="release-card__list">'
        highlights.each { |h| lines << %(              <li>#{h}</li>) }
        lines << '            </ul>'
      end
      lines << %(            <a class="release-card__link" href="./release-#{version}.html">View the demo <span aria-hidden="true">&rarr;</span></a>)
      lines << '          </article>'
      lines << '        </div>'
      lines.join("\n")
    end.join("\n")

    index = File.read('tasks/index.html').sub('{{releases}}', items)
    File.write "#{PUBLIC_DIR}/index.html", index
  end
end
