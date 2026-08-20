/**
 * Chrome flags shared by both ways the PDF pipeline gets a browser: the
 * long-lived shared one (docker/scripts/pdf-chrome) and the private one
 * rasterize.js launches when no shared browser is configured or reachable.
 * Exported from one place so the two can't drift apart.
 *
 * Everything past the sandbox/WebGL essentials is here purely to save memory -
 * background services, caches and extra renderer processes a one-shot print has
 * no use for. Measured on the dev stack: ~45MB saved per browser, with
 * byte-identical PDF output.
 */
module.exports = [
  '--no-sandbox',
  '--disable-setuid-sandbox',
  '--disable-dev-shm-usage',
  // Chrome no longer auto-falls-back to software WebGL (SwiftShader) -
  // without this, MapLibre GL gets no WebGL context at all in headless
  // Chrome and silently renders a blank map (everything else - tile
  // requests, the 'idle' event - still fires normally, so this was
  // invisible from the JS side).
  '--enable-unsafe-swiftshader',
  // Smaller tile/resource pools, as Chrome uses on low-memory devices.
  '--enable-low-end-device-mode',
  // Every page we print is same-origin, so Chrome would consolidate them into
  // one renderer anyway; saying so explicitly keeps a burst of concurrent jobs
  // from each paying for a process.
  '--renderer-process-limit=1',
  '--disable-features=site-per-process,IsolateOrigins,TranslateUI,BackForwardCache,MediaRouter,OptimizationHints',
  '--disable-background-networking',
  '--disable-sync',
  '--disable-extensions',
  '--disable-default-apps',
  '--disable-component-extensions-with-background-pages',
  '--disable-breakpad',
  '--disable-client-side-phishing-detection',
  '--no-first-run',
  '--mute-audio',
  '--disk-cache-size=1',
  '--media-cache-size=1',
  '--disable-gpu-shader-disk-cache'
];
