#!/usr/bin/env node
/**
 * Build-time gate for the PDF pipeline. Run from Dockerfile.deploy straight
 * after the Chrome install; a non-zero exit fails the image build, so a broken
 * browser can never reach staging.
 *
 * Every check here is a hard gate -- there are no tolerated exit codes.
 *
 *   1. chrome-args.js loads and is a non-empty array. Both runtime consumers
 *      (docker/scripts/pdf-chrome and rasterize.js next to this file) require
 *      it, so if it is missing or malformed every PDF fails at the first request
 *      with nothing in the build to warn you.
 *   2. executablePath() points at an executable FILE. This is the check that
 *      actually matters: an earlier version asserted on the DIRECTORY, which is
 *      exactly the thing that exists when the download has failed half-way.
 *      The call is wrapped in Promise.resolve() because puppeteer 25 returns a
 *      Promise from it; that also keeps working if it ever goes back to sync.
 *   3. Chrome really launches, with the same flags the runtime uses. Chrome
 *      ignores unknown flags, so this is not about catching flag drift -- it is
 *      about exercising the real launch path rather than a simplified one.
 *
 * Paths are resolved from __dirname so this does not care what WORKDIR is.
 */
const fs = require('fs')
const path = require('path')
const puppeteer = require('puppeteer')

const CHROME_ARGS_PATH = path.join(__dirname, 'chrome-args')

function fail (message) {
  console.error(`ERROR: ${message} -- every PDF export would fail.`)
  process.exit(1)
}

async function main () {
  let args
  try {
    args = require(CHROME_ARGS_PATH)
  } catch (e) {
    fail(`cannot load chrome-args.js (${CHROME_ARGS_PATH}): ${e.message}`)
  }
  if (!Array.isArray(args) || args.length === 0) {
    fail(`chrome-args.js did not export a non-empty array (got ${JSON.stringify(args)})`)
  }

  const executablePath = String(await Promise.resolve(puppeteer.executablePath()))
  let stat
  try {
    stat = fs.statSync(executablePath)
  } catch (e) {
    fail(`puppeteer's executablePath (${executablePath}) does not exist: ${e.message}`)
  }
  if (!stat.isFile()) {
    fail(`puppeteer's executablePath (${executablePath}) is not a file -- the download left a bare directory`)
  }
  try {
    fs.accessSync(executablePath, fs.constants.X_OK)
  } catch (e) {
    fail(`puppeteer's executablePath (${executablePath}) is not executable: ${e.message}`)
  }

  let browser
  try {
    // Copy: puppeteer SPLICES the caller's --disable-features entry out of the
    // array it is handed (it merges that flag with its own list), so passing the
    // required module directly would permanently shorten the cached singleton.
    browser = await puppeteer.launch({ args: [...args] })
  } catch (e) {
    fail(`puppeteer cannot launch ${executablePath}: ${e.message}`)
  }
  const version = await browser.version()
  await browser.close()

  console.log(`puppeteer OK: ${version} at ${executablePath}, ${args.length} shared flags`)
}

main().catch(e => fail(e && e.stack ? e.stack : String(e)))
