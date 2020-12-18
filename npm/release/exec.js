'use strict'
const childProcess = require('child_process')

module.exports.execSync = (command, opts) => {
  console.debug(command, opts)
  if (!process.env.DRY_RUN) {
    const stdout = childProcess.execSync(command, opts)
    process.stdout.write(stdout)
    return stdout
  }
}
