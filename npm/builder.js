module.exports = Builder;

var fs = require('fs');
var async = require('async');
var log = require('bestikk-log');
var bfs = require('bestikk-fs');
var OpalCompiler = require('bestikk-opal-compiler');

function Builder () {
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
    function (callback) { builder.replaceUnsupportedFeatures(callback); }, // replace unsupported features
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
  opalCompiler.compile('asciidoctor-revealjs', 'build/asciidoctor-revealjs.js', ['lib']);
  typeof callback === 'function' && callback();
};

Builder.prototype.replaceUnsupportedFeatures = function (callback) {
  log.task('Replace unsupported features');
  const path = 'lib/asciidoctor-revealjs/converter.rb';
  let data = fs.readFileSync(path, 'utf8');
  log.debug('Replace String#<< with Array#<<');
  data = data.replace(/([^ ]*) = ''/g, '$1 = \[\]');
  data = data.replace(/^(\s*)(_[a-z1-9_\[\]]*)$/gm, '$1$2 = $2 * \'\'');
  fs.writeFileSync(path, data, 'utf8');
  callback();
};

Builder.prototype.copyToDist = function (callback) {
  var builder = this;

  log.task('copy to dist/');
  builder.removeDistDirSync();
  bfs.copySync('build/asciidoctor-revealjs.js', 'dist/main.js');
  //bfs.copySync('templates/jade', 'dist/templates');
  typeof callback === 'function' && callback(); 
};

Builder.prototype.removeDistDirSync = function () {
  log.debug('remove dist directory');
  bfs.removeSync('dist');
  bfs.mkdirsSync('dist/templates');
};
