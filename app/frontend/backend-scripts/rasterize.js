// Note: in dev, a Docker memory allowance that is too low makes concurrent PDF
// requests time out or fail.
const fs = require('fs');
const puppeteer = require('puppeteer');
const CHROME_ARGS = require('./chrome-args');
const address = process.argv[2];
const output = process.argv[3];
const NAVIGATION_TIMEOUT = Number(process.env.PDF_NAVIGATION_TIMEOUT_MS || 60000);
const PDF_READY_TIMEOUT = Number(process.env.PDF_READY_TIMEOUT_MS || 90000);
const BROWSER_PORT = process.env.PDF_BROWSER_PORT || 9222;
const BROWSER_URL = `http://127.0.0.1:${BROWSER_PORT}`;
async function acquireBrowser () {
  const options = { protocolTimeout: PDF_READY_TIMEOUT };

  try {
    return { browser: await puppeteer.connect({ browserURL: BROWSER_URL, ...options }), shared: true };
  } catch (err) {
    console.error(`No shared browser at ${BROWSER_URL} (${err.message}); launching a private one.`);
  }
  console.warn("Couldn't use the shared Chrome launching its own Chrome now.")
  return { browser: await puppeteer.launch({ args: CHROME_ARGS, ...options }), shared: false };
}
function freezeMapCanvases (page) {
  return page.evaluate(async () => {
    const canvases = Array.from(document.querySelectorAll('canvas.maplibregl-canvas'));

    const images = canvases.map((canvas) => {
      const image = new Image();
      image.src = canvas.toDataURL('image/png');
      image.style.cssText = `width:${canvas.clientWidth}px;height:${canvas.clientHeight}px;display:block`;
      canvas.parentNode.replaceChild(image, canvas);

      const gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
      const loseContext = gl && gl.getExtension('WEBGL_lose_context');
      if (loseContext) loseContext.loseContext();

      return image;
    });

    // Printing a not-yet-decoded <img> leaves a blank rectangle.
    await Promise.all(images.map((image) => image.decode().catch(() => {})));

    return canvases.length;
  });
}

(async () => {
  let browser;
  let shared = false;
  let context;
  let page;

  try {
    ({ browser, shared } = await acquireBrowser());
    // A throwaway context per job so concurrent renders can't see each other's
    // cookies/storage, and one context.close() releases all the job allocated.
    context = shared ? await browser.createBrowserContext() : browser.defaultBrowserContext();
    page = await context.newPage();

    // So a readiness timeout can report what actually broke rather than just
    // "waited N ms" — the page usually says (component error, script 404).
    const pageErrors = [];
    page.on('pageerror', (err) => pageErrors.push(err.message));
    page.on('requestfailed', (request) => {
      pageErrors.push(`failed to load ${request.url()} (${(request.failure() || {}).errorText})`);
    });

    page.setDefaultNavigationTimeout(NAVIGATION_TIMEOUT);
    // page.pdf() takes its timeout from here, not from the navigation one, and
    // spends part of it on an internal document.fonts.ready wait — under the
    // 30s default the print step timed out on a loaded machine long after the
    // page had rendered. Same budget as the render.
    page.setDefaultTimeout(PDF_READY_TIMEOUT);

    page.setViewport({
      width: 1280,
      height: 1754,
      deviceScaleFactor: 2
    });

    // 'domcontentloaded', not 'load' or 'networkidle2'. 'networkidle2' never
    // settles behind anything that keeps reconnecting (Vite's HMR client).
    // 'load' waits for every asset — the same work __PDF_READY__ below waits
    // for, but under a second, shorter budget that concurrent dev renders
    // routinely blew on pages that then rendered fine. Nothing between here and
    // there needs assets loaded.
    const response = await page.goto(address, {waitUntil: 'domcontentloaded'});

    // page.goto() resolves for error pages too, and an error page mounts the
    // same islands, so __PDF_READY__ flips and the code below prints it —
    // handing the user a 404 or a transient 500 as a completed download.
    if (response && !response.ok()) {
      throw new Error(`${address} returned HTTP ${response.status()}`);
    }

    // `window.__PDF_READY__` (app/frontend/lib/pdfReady.ts) flips once every
    // island has mounted and anything doing post-mount async work (tiles, data
    // fetches) has reported itself done — a real "is it rendered" signal rather
    // than a fixed sleep. Throwing on timeout surfaces a failed PDF instead of
    // silently shipping a broken one.
    try {
      await page.waitForFunction(() => window.__PDF_READY__ === true, { timeout: PDF_READY_TIMEOUT });
    } catch (err) {
      if (pageErrors.length) {
        throw new Error(`${err.message}. The page reported: ${pageErrors.join(' | ')}`);
      }
      throw err;
    }

    // Must come after __PDF_READY__: on 'domcontentloaded' the stylesheets
    // carrying @font-face may not be parsed yet, so document.fonts.ready would
    // resolve on an empty font set.
    await page.evaluate(() => document.fonts.ready.then(() => true));

    // One more frame so the final paint after __PDF_READY__ (e.g. the map's
    // re-render on 'idle') lands before the print.
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));

    await freezeMapCanvases(page);

    const headerHTML = `<div style="padding-top:10px; padding-right:26px; width: 100%;">
      <p style="float:right; margin-bottom:0;">
        <span style="color:#000; font-family:'Hind Siliguri',Arial; font-size:5pt;">Protected Planet | </span>
        <span style="color:#000; font-family:'Hind Siliguri',Arial; font-size:5pt; font-weight:bold;">Page</span>
        <span style="color:#000; font-family:'Hind Siliguri',Arial; font-size:5pt; font-weight:bold; padding-left:2px;" class="pageNumber"></span>
        <span style="color:#000; font-family:'Hind Siliguri',Arial; font-size:5pt; padding:0 2px; display:inline-block"> of </span>
        <span style="color:#000; font-family:'Hind Siliguri',Arial; font-size:5pt; font-weight:bold;" class="totalPages"></span>
    </div>`;

    const footerHTML = `<div style="padding-right:26px; width: 100%;">
      <span style="color:#000; float:right; font-family:'Hind Siliguri',Arial; font-size:5pt; font-weight:bold;" class="date"></span>
    </div>`;

    const pdf = await page.pdf({
      displayHeaderFooter: true,
      headerTemplate: headerHTML,
      footerTemplate: footerHTML,
      format: 'A4',
      margin: {
        top: '60px',
        right: '20px',
        bottom: '60px',
        left: '20px',
      },
      printBackground: true,
      scale: .63
    });
    fs.writeFileSync(output, pdf);
  } catch (err) {
    console.error(`rasterize.js failed for ${address}:`, err);
    process.exitCode = 1;
  } finally {
    // Order matters: tear our page/context down first, so a shared browser is
    // left clean, then let go of the browser.
    try {
      if (page && !page.isClosed()) await page.close();
      if (shared && context) await context.close();
    } catch (err) {
      console.error('rasterize.js cleanup failed:', err.message);
    }

    if (browser) await (shared ? browser.disconnect() : browser.close());
  }
})();
