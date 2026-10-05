/**
 * Chrome flags shared by both ways the PDF pipeline gets a browser: the
 * long-lived one (docker/scripts/pdf-chrome) and the private one rasterize.js
 * launches as a fallback, so the two can't drift apart.
 *
 * Past the sandbox/WebGL essentials these only save memory — background
 * services, caches and renderer processes a one-shot print has no use for.
 * ~45MB per browser on the dev stack, with byte-identical output.
 *
 * NOTE for callers: puppeteer SPLICES the caller's --disable-features entry out
 * of the array it is handed, merging that flag into its own list. Pass a copy
 * (`[...CHROME_ARGS]`), never this array itself — it is the cached require()
 * singleton and a second launch in the same process would lose the flag.
 *
 * Two of these were tuned against the dev VM (1.5GB / 3 CPU for the whole
 * stack), where memory was the binding constraint. On a real deployment host it
 * usually isn't, so both are env-tunable rather than baked in — see below.
 */

// One renderer per concurrent job is the honest setting: ~90MB each, so ~450MB
// at full capsule against the browser's own ~440MB. Tune with
// PDF_RENDERER_PROCESS_LIMIT, but do not set it below the capsule concurrency.
//
// A non-numeric or non-positive value falls back to the default rather than
// being passed through: Chrome silently accepts `--renderer-process-limit=NaN`
// and then behaves as if no limit were set at all, which is the opposite of
// what anyone reaching for this knob wants.
const RENDERER_PROCESS_LIMIT = (() => {
  const configured = Number(process.env.PDF_RENDERER_PROCESS_LIMIT)
  return Number.isInteger(configured) && configured > 0 ? configured : 5
})()

// Smaller tile/resource pools, as Chrome uses on low-memory devices. OFF unless
// asked for: it throttles exactly the map raster work these PDFs are mostly made
// of, so it is a dev concession, not something to ship.
//
// The dev stack needs it - the whole thing lives in a 1.5GB / 3 CPU VM - so
// docker-compose.yml sets PDF_LOW_END_DEVICE_MODE=1 on the sidekiq service,
// alongside the other dev-only PDF budget overrides. Deployment leaves it unset.
const PDF_LOW_END_DEVICE_MODE = ['1', 'true'].includes(process.env.PDF_LOW_END_DEVICE_MODE || null)

module.exports = [
  '--no-sandbox',
  '--disable-setuid-sandbox',
  '--disable-dev-shm-usage',
  // Chrome no longer auto-falls back to software WebGL, so without this
  // MapLibre gets no context and renders a blank map — invisible from JS,
  // since tile requests and 'idle' still fire normally.
  '--enable-unsafe-swiftshader',
  ...(PDF_LOW_END_DEVICE_MODE ? ['--enable-low-end-device-mode'] : []),
  `--renderer-process-limit=${RENDERER_PROCESS_LIMIT}`,
  // Every page we print is same-origin, so Chrome would consolidate them
  // anyway; explicit here so a burst of jobs doesn't each pay for a process.
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
]
