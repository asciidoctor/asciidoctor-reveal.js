import childProcess from 'node:child_process'
import path from 'node:path'
import { writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import process from 'node:process'

const dryRun = Boolean(process.env.DRY_RUN)

export const projectRootDirectory = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', '..')

// Run a command, or just print it when DRY_RUN is set.
export function execSync (command, opts) {
  console.debug(command, opts)
  if (dryRun) {
    return
  }
  const stdout = childProcess.execSync(command, opts)
  process.stdout.write(stdout)
  return stdout
}

// Write a file, or just print what would be written when DRY_RUN is set.
export function writeFile (filePath, content) {
  if (dryRun) {
    console.debug(`Dry run! ${filePath} will be updated:\n${content}`)
  } else {
    writeFileSync(filePath, content)
  }
}

// Read the release version from the command line arguments or exit.
export function requireVersion (script) {
  const releaseVersion = process.argv[2]
  if (!releaseVersion) {
    console.error(`Release version is undefined, please specify a version \`npm run ${script} 1.0.0\``)
    process.exit(9)
  }
  return releaseVersion
}

// Ensure the working directory is clean, and we are on the main branch or exit.
export function ensureCleanMainBranch (action) {
  try {
    childProcess.execSync('git diff-index --quiet HEAD --', { cwd: projectRootDirectory })
  } catch (e) {
    console.error('Git working directory not clean')
    process.stdout.write(childProcess.execSync('git status -s'))
    process.exit(1)
  }
  const branchName = childProcess.execSync('git symbolic-ref --short HEAD', { cwd: projectRootDirectory }).toString('utf-8').trim()
  if (branchName !== 'main') {
    console.error(`${action} must be performed on main branch`)
    process.exit(1)
  }
}
