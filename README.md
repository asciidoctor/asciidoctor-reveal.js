# reveal.js converter for Asciidoctor.js

A reveal.js converter for [Asciidoctor.js](https://github.com/asciidoctor/asciidoctor.js) that transforms an AsciiDoc document into an HTML5 presentation designed to be executed by the [reveal.js](http://lab.hakim.se/reveal-js/) presentation framework.

For setup instructions and the AsciiDoc syntax to use to write a presentation see the module's documentation at [https://github.com/asciidoctor/asciidoctor-reveal.js](https://github.com/asciidoctor/asciidoctor-reveal.js).


## common used command for hacking this repo

* `bundle exec rake build`: regenerate converter.rb
* `bundle exec asciidoctor-revealjs test.adoc --trace`: convert test.adoc to html slide
* `bundle exec rake build:js`: build the converter into Javascript
* `npm run package`: generate binary executable for linux, macos and windows. (you should run `bundle exec rake build:js` firstly)