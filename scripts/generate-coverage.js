const { execSync } = require('child_process')
const fs = require('fs')
const fsPromise = require('node:fs/promises')
const path = require('path')
const chalk = require('chalk')

const log = console.log

const COVERAGE_DIR_NAME = 'coverage'
const REPORTS_PATH = path.resolve(process.cwd(), '.nyc_reports')

const createPath = (basePathname, pathname = '') => {
  return path.resolve(process.cwd(), basePathname, pathname)
}

const createNycOutputDir = dirPath => {
  const isExist = fs.existsSync(dirPath)

  if (!isExist) fs.mkdirSync(dirPath)
}

const copyCoverageFile = (originFile, destinationFile) => {
  log(`- ${originFile} to ${destinationFile}`)
  fs.copyFileSync(originFile, destinationFile)
}

const execCopyingReports = dirs => {
  const tasks = []
  createNycOutputDir(REPORTS_PATH)

  log(chalk.bgWhite.black('[COPYING FILES]'))

  return new Promise(resolve => {
    for (let dir of dirs) {
      const currentPath = createPath(dir)

      tasks.push({ run: () => copyCoverageReports(dir, currentPath) })
    }

    Promise.all(tasks.map(task => task.run())).then(res => {
      resolve(res)
    })
  })
}
const copyCoverageReports = async (groupDirName, currentPath) => {
  const directories = await fsPromise.readdir(currentPath)

  if (Boolean(directories?.length)) {
    for (const directory of directories) {
      const currentDirectory = createPath(currentPath, directory)

      const stats = await fsPromise.stat(currentDirectory)

      if (stats.isDirectory()) {
        const coverageFile = createPath(
          currentDirectory,
          `${COVERAGE_DIR_NAME}/coverage-final.json`
        )

        if (fs.existsSync(coverageFile)) {
          const getCoverageFile = createPath(REPORTS_PATH, `${directory}.json`)

          copyCoverageFile(coverageFile, getCoverageFile)
        } else {
          if (!currentDirectory.match(/[\\/](node_modules)[\\/]/)) {
            copyCoverageReports(groupDirName, currentDirectory)
          }
        }
      }
    }
  }

  return 'DONE!'
}

// Run
;(dirs => {
  execCopyingReports(dirs).then(res => {
    // ---- Merge coverage reports ----
    execSync('npx nyc report', { stdio: 'inherit' })
  })
})((dirs = []))
