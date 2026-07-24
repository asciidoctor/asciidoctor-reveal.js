# frozen_string_literal: true

# Shared between tasks/examples.rake and tasks/release_notes.rake: both convert
# a directory of standalone presentations that reference reveal.js/Font Awesome
# assets relatively, so both need a local copy of those assets and a way to
# serve their output over HTTP for local preview.

# Copies reveal.js/Font Awesome assets from node_modules into dest_root (run
# `npm install` first). The Font Awesome directory name bakes in its version
# (matched by package.json's exact, non-caret pin) — bumping it means renaming
# its directory here too.
def copy_node_module_assets(dest_root, project_root)
  {
    'reveal.js' => "#{dest_root}/reveal.js",
    '@fortawesome/fontawesome-free' => "#{dest_root}/Font-Awesome-6.7.2"
  }.each do |package, dest_relative|
    src = File.expand_path("node_modules/#{package}", project_root)
    dest = File.expand_path(dest_relative, project_root)
    raise "#{package} not found at #{src}; run `npm install` first" unless Dir.exist?(src)

    FileUtils.rm_rf(dest)
    FileUtils.cp_r(src, dest)
    puts "Copied #{package} to #{dest}"
  end
end

# Minimal static file server built on the stdlib (no WEBrick / external gem).
# Serves `root` and exposes an auto-generated index listing every HTML page
# found there.
def serve_static_dir(root, host: '127.0.0.1', port: 5000)
  require 'socket'

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
