const log = require('bestikk-log');
const bfs = require('bestikk-fs');
const CompilerModule = require('./compiler.js');

const clean = function () {
  log.task('clean');
  removeBuildDirSync(); // remove build directory
};

const removeBuildDirSync = function () {
  log.debug('remove build directory');
  bfs.removeSync('build');
  bfs.mkdirsSync('build');
};

const compile = function () {
  CompilerModule.compile();
};

const copyToDist = function () {
  log.task('copy to dist/');
  removeDistDirSync();
  bfs.copySync('build/asciidoctor-reveal.js', 'dist/main.js');
};

const removeDistDirSync = function () {
  log.debug('remove dist directory');
  bfs.removeSync('dist');
  bfs.mkdirsSync('dist');
};

if (process.env.SKIP_BUILD) {
  log.info('SKIP_BUILD environment variable is true, skipping "build" task');
  return;
}

clean();
compile();
copyToDist();
