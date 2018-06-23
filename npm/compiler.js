const fs = require('fs');
const log = require('bestikk-log');
const OpalBuilder = require('opal-compiler').Builder;

module.exports.compile = function () {
  log.task('compile');

  const opalBuilder = OpalBuilder.create();
  opalBuilder.appendPaths('lib');
  opalBuilder.setCompilerOptions({dynamic_require_severity: 'ignore'});
  const module = 'asciidoctor-revealjs';
  log.debug(module);
  const data = opalBuilder.build(module).toString();
  fs.writeFileSync('build/asciidoctor-reveal.js', data, 'utf8');
};
