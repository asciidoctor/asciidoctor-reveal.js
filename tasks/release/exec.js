import childProcess from 'node:child_process'
import process from 'node:process'

export function execSync (command, opts) {
  console.debug(command, opts)
  if (!process.env.DRY_RUN) {
    const stdout = childProcess.execSync(command, opts)
    process.stdout.write(stdout)
    return stdout
  }
}
