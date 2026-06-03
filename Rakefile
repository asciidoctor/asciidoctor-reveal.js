#!/usr/bin/env rake
# frozen_string_literal: true

require 'asciidoctor'
require 'asciidoctor/doctest'
require 'colorize'
require 'rake/testtask'

PUBLIC_DIR = 'public'

desc 'Clean public directory'
task :clean do
  rm_rf PUBLIC_DIR
end

# Loads the converter so its backend is registered with Asciidoctor.
desc 'Load converter'
task 'load-converter' do
  require_relative 'lib/asciidoctor_revealjs'
end

DocTest::RakeTasks.new do |t|
  t.output_examples :html, path: 'test/doctest'
  t.input_examples :asciidoc, path: [*DocTest.examples_path, 'examples']
  t.converter = DocTest::HTML::Converter
  t.converter_opts = { backend_name: 'revealjs' }
end

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/asciidoctor_revealjs/*_test.rb']
  t.warning = false
end

namespace :examples do
  # The examples reference reveal.js assets relatively (reveal.js/dist/...), so a
  # local copy must live under examples/. That directory is gitignored, hence the
  # copy from node_modules on demand.
  desc 'Copy reveal.js assets into the examples directory'
  task :assets do
    src = File.expand_path('node_modules/reveal.js', __dir__)
    dest = File.expand_path('examples/reveal.js', __dir__)
    raise "reveal.js not found at #{src}; run `npm install` first" unless Dir.exist?(src)

    FileUtils.rm_rf(dest)
    FileUtils.cp_r(src, dest)
    puts "Copied reveal.js assets to #{dest}"
  end

  # converted slides will be put in examples/ directory
  desc 'Converts all the test slides into fully working examples that you can look in a browser'
  task convert: ['load-converter', :assets] do
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

  desc 'Serve'
  task serve: :assets do
    # Minimal static file server built on the stdlib (no WEBrick / external gem).
    # Serves the examples/ directory and exposes an auto-generated index listing
    # every HTML page found there.
    require 'socket'

    host = '127.0.0.1'
    port = 5000
    root = File.expand_path('examples', __dir__)

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

  desc 'Publish'
  task :publish do
    FileUtils.rm_rf PUBLIC_DIR
    Dir.mkdir PUBLIC_DIR
    Dir.mkdir "#{PUBLIC_DIR}/reveal.js"
    FileUtils.cp 'src/index.html', "#{PUBLIC_DIR}/index.html"
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

desc 'Run all tests'
task 'test' => 'doctest'

desc 'Test using doctest'
task 'doctest:test' => 'load-converter'

desc 'Generate doctest'
task 'doctest:generate' => 'load-converter'

desc 'No task specified, run tes'
task default: :test
