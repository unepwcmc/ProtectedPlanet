/**
 * Chrome flags shared by both ways the PDF pipeline gets a browser: the
 * long-lived one (docker/scripts/pdf-chrome) and the private one rasterize.js
 * launches as a fallback, so the two can't drift apart.
 *
 * Past the sandbox/WebGL essentials these only save memory — background
 * services, caches and renderer processes a one-shot print has no use for.
 * ~45MB per browser on the dev stack, with byte-identical output.
 */
module.exports = [
  '--no-sandbox',
  '--disable-setuid-sandbox',
  '--disable-dev-shm-usage',
  // Chrome no longer auto-falls back to software WebGL, so without this
  // MapLibre gets no context and renders a blank map — invisible from JS,
  // since tile requests and 'idle' still fire normally.
  '--enable-unsafe-swiftshader',
  // Smaller tile/resource pools, as Chrome uses on low-memory devices.
  '--enable-low-end-device-mode',
  // Every page we print is same-origin, so Chrome would consolidate them
  // anyway; explicit here so a burst of jobs doesn't each pay for a process.
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
