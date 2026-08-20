const puppeteer = require('puppeteer');
const address = process.argv[2];
const captureDelay = 10000;
const output = process.argv[3];

// page.waitFor() was renamed to waitForTimeout in puppeteer 10 and removed in 22,
// so use a plain timer -- it works on every version and has no deprecation path.
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

// The whole point of rasterising is to capture the rendered page, and the map is
// the slowest thing on it. Under puppeteer 5 (Chromium 88) the Map chunk could not
// even be parsed, so every PDF silently came out without a map; waiting for the
// canvas makes that failure loud instead of invisible. Best-effort: pages that
// legitimately have no map must still render, so a miss is not fatal.
async function waitForMapIfPresent(page, timeout) {
  const hasMapHost = await page.evaluate(
    () => !!document.querySelector('[data-controller="turbo-mount-map"]')
  );
  if (!hasMapHost) return 'no map on this page';
  try {
    await page.waitForSelector('.maplibregl-canvas', { timeout });
    return 'map canvas rendered';
  } catch (e) {
    return 'WARNING: map host present but no canvas after ' + timeout + 'ms';
  }
}

(async () => {
  const browser = await puppeteer.launch({
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox'
    ]
  });
  const page = await browser.newPage();
  
  page.setViewport({
    width: 1200,
    height: 1754,
    deviceScaleFactor: 2
  });

  await page.goto(address, {waitUntil: 'networkidle2'});

  const mapStatus = await waitForMapIfPresent(page, captureDelay);
  console.error('[rasterize] ' + mapStatus);
  await sleep(captureDelay);

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

  await page.pdf({
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
    path: output, 
    printBackground: true,
    scale: .63
  });

  await browser.close();
})();