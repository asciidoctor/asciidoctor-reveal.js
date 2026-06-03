# frozen_string_literal: true

namespace :examples do
  desc 'Build the public/ release showcase site (landing page and release demos)'
  task :publish do
    FileUtils.rm_rf PUBLIC_DIR
    Dir.mkdir PUBLIC_DIR
    Dir.mkdir "#{PUBLIC_DIR}/reveal.js"
    FileUtils.cp 'tasks/index.html', "#{PUBLIC_DIR}/index.html"
    FileUtils.cp_r 'node_modules/reveal.js/', PUBLIC_DIR.to_s
    FileUtils.cp_r 'examples/images/', PUBLIC_DIR.to_s
    FileUtils.cp 'examples/release-4.0.html', "#{PUBLIC_DIR}/release-4.0.html"
    FileUtils.cp 'examples/release-4.0.css', "#{PUBLIC_DIR}/release-4.0.css"
    FileUtils.cp 'examples/release-4.1.html', "#{PUBLIC_DIR}/release-4.1.html"
    FileUtils.cp 'examples/release-4.1.css', "#{PUBLIC_DIR}/release-4.1.css"
    FileUtils.cp 'examples/a11y-dark.css', "#{PUBLIC_DIR}/a11y-dark.css"
    FileUtils.cp 'examples/release-5.1.html', "#{PUBLIC_DIR}/release-5.1.html"
    FileUtils.cp 'examples/release-5.1.css', "#{PUBLIC_DIR}/release-5.1.css"
    FileUtils.cp 'examples/release-5.2.html', "#{PUBLIC_DIR}/release-5.2.html"
  end
end
