/**
 * In dev mode if you give Docker all containers too low 
 * memory to use it will likely to timeout or fail on multiple PDF generation requests
 */
const fs = require('fs');
const puppeteer = require('puppeteer');
const CHROME_ARGS = require('./chrome-args');
const address = process.argv[2];
const output = process.argv[3];

// Only bounds fetching the HTML document itself (see the goto below), not the
// assets or the render - so it can stay short even on a loaded machine.
const NAVIGATION_TIMEOUT = Number(process.env.PDF_NAVIGATION_TIMEOUT_MS || 60000);
// Generous enough to survive several renders running at once - a page that is
// merely queued behind its siblings for CPU (software WebGL is expensive and
// there are only a handful of cores) is not a broken page. Kept configurable so
// a machine running a higher PDF_CONCURRENCY can raise it without a code change.
// This is the *whole* budget for loading assets, mounting and rendering, so in
// dev it also has to cover every module being compiled on demand by the Vite
// dev server (docker-compose.yml raises it there for exactly that reason).
const PDF_READY_TIMEOUT = Number(process.env.PDF_READY_TIMEOUT_MS || 90000);

// A long-lived, shared Chrome to render in, when one is listening here
// (docker/scripts/pdf-chrome, which defaults to the same port - starting that
// script is the whole of the configuration). Only the port is worth an env var
// because the browser always lives next to the worker that drives it - the same
// container in dev, the same host in production - so the address is never
// anything but loopback.
//
// Launching a browser per job is what actually costs memory: measured on the dev
// stack, a fresh browser sitting on a blank page is ~440MB of anonymous memory
// while the page's own content - map, charts, everything - adds only ~90MB on
// top. Three concurrent jobs therefore need ~1.6GB if each launches its own
// browser, but ~550MB total if they share one. Nothing listening (production,
// which starts no shared Chrome) falls back to launching one per job.
const BROWSER_PORT = process.env.PDF_BROWSER_PORT || 9222;
const BROWSER_URL = `http://127.0.0.1:${BROWSER_PORT}`;

// Returns the browser plus whether we are borrowing someone else's - a shared
// browser must be *disconnected* from at the end, never closed, or the next job
// finds a dead endpoint. Failing to connect is an expected state rather than a
// misconfiguration: where no shared Chrome runs the connect is refused on
// loopback in a few hundred ms - nothing against a render measured in tens of
// seconds - and each job launches its own browser.
async function acquireBrowser () {
  // protocolTimeout bounds every individual CDP round-trip (each page.evaluate,
  // each waitForFunction poll) and defaults to 180s, independently of any timeout
  // passed to a specific call. On a machine loaded enough for one round-trip to
  // take that long, jobs died with a bare "Waiting failed" whose real cause -
  // "Runtime.callFunctionOn timed out" - was only visible in the error's `cause`.
  // Tied to the render budget so one knob scales every wait a busy machine can
  // stretch. It can only be set here, at launch/connect time.
  const options = { protocolTimeout: PDF_READY_TIMEOUT };

  try {
    return { browser: await puppeteer.connect({ browserURL: BROWSER_URL, ...options }), shared: true };
  } catch (err) {
    console.error(`No shared browser at ${BROWSER_URL} (${err.message}); launching a private one.`);
  }

  return { browser: await puppeteer.launch({ args: CHROME_ARGS, ...options }), shared: false };
}

// Swaps every live MapLibre canvas for a static <img> of the same pixels, then
// force-loses its WebGL context. The map is finished by this point (that is what
// __PDF_READY__ means), so the context is pure overhead - and page.pdf() below
// re-lays-out and rasterises the whole document, which is the worst moment to
// still be holding a drawing buffer. Relies on the map being created with
// preserveDrawingBuffer (see useMapInstance.ts), without which toDataURL would
// return a blank image.
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

    // Decode before returning: printing a not-yet-decoded <img> would put a
    // blank rectangle where the map should be.
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

    // A throwaway context per job when sharing, so concurrent renders can't see
    // each other's cookies/storage and everything the job allocated is released
    // by the single context.close() below.
    context = shared ? await browser.createBrowserContext() : browser.defaultBrowserContext();
    page = await context.newPage();

    page.setDefaultNavigationTimeout(NAVIGATION_TIMEOUT);
    // A separate budget from the navigation one, defaulting to 30s. page.pdf()
    // takes its timeout from here - and spends part of it on its own internal
    // document.fonts.ready wait - so on a loaded machine the print step itself
    // failed with "Timed out after waiting 30000ms" long after the page had
    // finished rendering. Same budget as the render, for consistency.
    page.setDefaultTimeout(PDF_READY_TIMEOUT);

    page.setViewport({
      width: 1280,
      height: 1754,
      deviceScaleFactor: 2
    });

    // 'domcontentloaded' (the HTML is parsed) rather than 'load' or 'networkidle2'.
    // 'networkidle2' is fooled by anything that keeps reconnecting in the background
    // (e.g. Vite's dev-server HMR client retrying indefinitely) and never settles at
    // all. 'load' does settle, but it waits for every asset - the same work that
    // __PDF_READY__ below already waits for, only under a second, shorter budget. In
    // dev, where each module is compiled on demand by the Vite dev server, two
    // concurrent renders routinely blew that 60s budget on pages that then rendered
    // fine. Waiting once, on the signal that actually means "rendered", removes the
    // duplicate deadline; nothing between here and there needs assets to be loaded.
    const response = await page.goto(address, {waitUntil: 'domcontentloaded'});

    // page.goto() resolves for error pages too, and an error page is still a
    // full app page: it mounts the same islands, so __PDF_READY__ flips and
    // everything below happily prints it. Without this check a 404 (retired
    // site id, typo'd ISO) or a transient 500 from the app is handed to the
    // user as a completed, several-hundred-KB download.
    if (response && !response.ok()) {
      throw new Error(`${address} returned HTTP ${response.status()}`);
    }

    // `window.__PDF_READY__` (app/frontend/lib/pdfReady.ts) only flips true once
    // every Vue island has mounted AND anything doing its own post-mount async
    // work (map tile loading, data fetches) has reported itself done - a real
    // "is it actually rendered" signal instead of a fixed sleep that either
    // wastes time on fast pages or ships an incomplete PDF on slow ones. If this
    // never resolves (bundle failed to load, a component never signals done),
    // throwing here surfaces a failed PDF rather than silently shipping a broken
    // one.
    await page.waitForFunction(() => window.__PDF_READY__ === true, { timeout: PDF_READY_TIMEOUT });

    // After __PDF_READY__, not before: we now navigate on 'domcontentloaded', so
    // ahead of this point the stylesheets carrying the @font-face rules may not
    // even be parsed yet and document.fonts.ready would resolve on an empty font
    // set. By here every island has mounted, so the fonts they need are known
    // and requested, and this waits for the ones still in flight.
    await page.evaluate(() => document.fonts.ready.then(() => true));

    // One more frame so the final paint after __PDF_READY__ flips (e.g. the
    // map's own re-render once its 'idle' handler runs) actually lands before
    // the screenshot is taken.
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
    // Order matters: tear our own page/context down first so a shared browser is
    // left clean, then let go of the browser itself.
    try {
      if (page && !page.isClosed()) await page.close();
      if (shared && context) await context.close();
    } catch (err) {
      console.error('rasterize.js cleanup failed:', err.message);
    }

    if (browser) await (shared ? browser.disconnect() : browser.close());
  }
})();
