# frozen_string_literal: true

require 'tmpdir'

namespace :examples do
  # The examples reference reveal.js and Font Awesome assets relatively
  # (reveal.js/dist/..., Font-Awesome-6.7.2/js/...), so a local copy must live
  # under examples/. That directory is gitignored, hence the copy from
  # node_modules on demand. The Font Awesome directory name bakes in its
  # version (matched by package.json's exact, non-caret pin) — bumping it
  # means renaming its directory here too.
  desc 'Copy reveal.js/Font Awesome assets from node_modules into examples/ (run `npm install` first)'
  task :assets do
    {
      'reveal.js' => 'examples/reveal.js',
      '@fortawesome/fontawesome-free' => 'examples/Font-Awesome-6.7.2'
    }.each do |package, dest_relative|
      src = File.expand_path("node_modules/#{package}", PROJECT_ROOT)
      dest = File.expand_path(dest_relative, PROJECT_ROOT)
      raise "#{package} not found at #{src}; run `npm install` first" unless Dir.exist?(src)

      FileUtils.rm_rf(dest)
      FileUtils.cp_r(src, dest)
      puts "Copied #{package} to #{dest}"
    end
  end

  # reveal.js-plugins@4.6.0 lists `npm` itself as a dependency (upstream
  # packaging mistake), which drags in npm's entire internal tooling tree —
  # dozens of vulnerable transitive deps for a plugin package that never
  # touches any of it at runtime. Fetched via `npm pack` (downloads the
  # tarball only, no dependency resolution) instead of a normal
  # devDependency, to keep it out of package(-lock).json entirely.
  desc 'Fetch reveal.js-plugins assets via `npm pack` into examples/ (bypasses its broken `npm` dependency)'
  task 'assets:reveal-js-plugins' do
    version = '4.6.0'
    dest = File.expand_path("examples/reveal.js-plugins-#{version}", PROJECT_ROOT)
    Dir.mktmpdir do |tmp|
      sh 'npm', 'pack', "reveal.js-plugins@#{version}", '--pack-destination', tmp, '--silent'
      tarball = Dir.glob(File.join(tmp, '*.tgz')).first
      raise "npm pack did not produce a tarball in #{tmp}" unless tarball

      sh 'tar', 'xzf', tarball, '-C', tmp
      FileUtils.rm_rf(dest)
      FileUtils.cp_r(File.join(tmp, 'package'), dest)
    end
    puts "Copied reveal.js-plugins to #{dest}"
  end

  # converted slides will be put in examples/ directory
  desc 'Convert every examples/*.adoc file into a browsable reveal.js presentation'
  task convert: ['load-converter', :assets, 'assets:reveal-js-plugins'] do
    Dir.glob('examples/*.adoc') do |f|
      print "Converting file #{f}... "
      out = Asciidoctor.convert_file f,
                                     safe: 'safe',
                                     backend: 'revealjs',
                                     base_dir: 'examples'
      if out.instance_of? Asciidoctor::Document
        puts '✔️'.green
      else
        puts '✖️'.red
      end
    end
  end

  desc 'Serve the converted examples/ over HTTP at http://127.0.0.1:5000'
  task serve: [:assets, 'assets:reveal-js-plugins'] do
    # Minimal static file server built on the stdlib (no WEBrick / external gem).
    # Serves the examples/ directory and exposes an auto-generated index listing
    # every HTML page found there.
    require 'socket'

    host = '127.0.0.1'
    port = 5000
    root = File.expand_path('examples', PROJECT_ROOT)

    content_types = {
      '.html' => 'text/html; charset=utf-8',
      '.css' => 'text/css; charset=utf-8',
      '.js' => 'text/javascript; charset=utf-8',
      '.mjs' => 'text/javascript; charset=utf-8',
      '.json' => 'application/json; charset=utf-8',
      '.svg' => 'image/svg+xml',
      '.png' => 'image/png',
      '.jpg' => 'image/jpeg',
      '.jpeg' => 'image/jpeg',
      '.gif' => 'image/gif',
      '.ico' => 'image/x-icon',
      '.woff' => 'font/woff',
      '.woff2' => 'font/woff2',
      '.ttf' => 'font/ttf'
    }.freeze

    index_page = lambda do
      items = Dir.glob('*.html', base: root).sort.map do |name|
        %(      <li><a href="/#{name}">#{name}</a></li>)
      end.join("\n")
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <title>asciidoctor-revealjs examples</title>
        </head>
        <body>
          <h1>Examples</h1>
          <ul>
        #{items}
          </ul>
        </body>
        </html>
      HTML
    end

    respond = lambda do |client, status, type, body|
      client.write "HTTP/1.1 #{status}\r\n"
      client.write "Content-Type: #{type}\r\n"
      client.write "Content-Length: #{body.bytesize}\r\n"
      client.write "Connection: close\r\n\r\n"
      client.write body
    end

    server = TCPServer.new(host, port)
    puts "View rendered examples at: http://#{host}:#{port}/"
    puts 'Exit with Ctrl-C'

    begin
      loop do
        Thread.new(server.accept) do |client|
          request_line = client.gets
          next unless request_line

          _method, raw_path, = request_line.split
          # Drain the remaining request headers.
          while (line = client.gets) && line != "\r\n"; end

          path = raw_path.to_s.split('?', 2).first
          decoded = path.gsub(/%([0-9A-Fa-f]{2})/) { Regexp.last_match(1).hex.chr }

          if decoded == '/'
            respond.call(client, '200 OK', 'text/html; charset=utf-8', index_page.call.b)
            next
          end

          full = File.expand_path(decoded.sub(%r{\A/}, ''), root)
          if full.start_with?("#{root}#{File::SEPARATOR}") && File.file?(full)
            type = content_types[File.extname(full).downcase] || 'application/octet-stream'
            respond.call(client, '200 OK', type, File.binread(full))
          else
            respond.call(client, '404 Not Found', 'text/plain; charset=utf-8', "Not Found\n".b)
          end
        rescue Errno::EPIPE, Errno::ECONNRESET
          # Client disconnected before we finished writing; ignore.
        ensure
          client.close
        end
      end
    rescue Interrupt
      puts "\nBye"
    ensure
      server.close
    end
  end
end
