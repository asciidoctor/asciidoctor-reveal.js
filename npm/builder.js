module.exports = Builder;

var async = require('async');
var log = require('bestikk-log');
var bfs = require('bestikk-fs');
var fs = require('fs');
var path = require('path');
var OpalCompiler = require('bestikk-opal-compiler');

function Builder () {
  this.examplesDir = 'examples';
}

Builder.prototype.build = function (callback) {
  if (process.env.SKIP_BUILD) {
    log.info('SKIP_BUILD environment variable is true, skipping "build" task');
    callback();
    return;
  }
  if (process.env.DRY_RUN) {
    log.debug('build');
    callback();
    return;
  }
  var builder = this;
  var start = process.hrtime();

  async.series([
    function (callback) { builder.clean(callback); }, // clean
    function (callback) { builder.compile(callback); }, // compile
    function (callback) { builder.copyToDist(callback); } // copy to dist
  ], function () {
    log.success('Done in ' + process.hrtime(start)[0] + 's');
    typeof callback === 'function' && callback();
  });
};

Builder.prototype.clean = function (callback) {
  log.task('clean');
  this.removeBuildDirSync(); // remove build directory
  callback();
};

Builder.prototype.removeBuildDirSync = function () {
  log.debug('remove build directory');
  bfs.removeSync('build');
  bfs.mkdirsSync('build');
};

Builder.prototype.compile = function (callback) {
  log.task('compile');
  var opalCompiler = new OpalCompiler({dynamicRequireLevel: 'ignore'});
  opalCompiler.compile('asciidoctor-revealjs', 'build/asciidoctor-reveal.js', ['lib']);
  typeof callback === 'function' && callback();
};

Builder.prototype.copyToDist = function (callback) {
  var builder = this;

  log.task('copy to dist/');
  builder.removeDistDirSync();
  bfs.copySync('build/asciidoctor-reveal.js', 'dist/main.js');
  //bfs.copySync('templates/jade', 'dist/templates');
  typeof callback === 'function' && callback(); 
};

Builder.prototype.removeDistDirSync = function () {
  log.debug('remove dist directory');
  bfs.removeSync('dist');
  bfs.mkdirsSync('dist');
};

Builder.prototype.examples = function (callback) {
  const builder = this;

  async.series([
    callback => builder.build(callback), // Build
    callback => builder.convertExamples(callback), // Convert the examples
  ], () => {
    log.info(`
Examples will be converted from AsciiDoc to HTML for Reveal.js. We expect no errors to happen.`);
    log.success(`Examples were converted and generated in: build/examples/`);
    typeof callback === 'function' && callback();
  });
};

Builder.prototype.convertExamples = function (callback) {
  log.task('convert examples');

  // Load asciidoctor.js and local asciidoctor-reveal.js
  var asciidoctor = require('asciidoctor.js')();
  require('../build/asciidoctor-reveal.js');

  // Convert *a* document using the reveal.js converter
  var attributes = {'revealjsdir': 'node_modules/reveal.js@'};
  var options = {safe: 'safe', backend: 'revealjs', attributes: attributes, to_dir: this.examplesDir};


  fs.readdir(this.examplesDir, (err, files) => {
    files.forEach(filename => {
      if (path.extname(filename) == '.adoc') {
        try {
          asciidoctor.convertFile(path.join(this.examplesDir, filename), options);
          log.info(`Successfully converted ${filename}`);
        }
        catch (err) {
          log.error(`Error converting ${filename}: ${err}`);
        }
      }
    });
  })

  callback();
};
