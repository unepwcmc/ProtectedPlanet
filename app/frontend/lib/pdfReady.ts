// Gives the PDF rasterizer a real "done rendering" signal instead of a fixed
// sleep. `window.__PDF_READY__` flips true once every island's mount promise
// has settled (markIslandScanComplete, from turboMount.ts) and every component
// doing post-mount async work has reported in (registerPendingRender).
//
// Set eagerly rather than left undefined, so a page with no async work gets a
// defined `false` immediately. A page whose bundle never loads leaves it
// undefined forever — the fail-loudly case rasterize.js wants.
const pending = new Set<symbol>()
let scanComplete = false

function updateFlag(): void {
  const ready = scanComplete && pending.size === 0
  const wasReady = (window as unknown as { __PDF_READY__?: boolean }).__PDF_READY__
  ;(window as unknown as { __PDF_READY__?: boolean }).__PDF_READY__ = ready

  // Dev only — Vite replaces this with `false` in a build, so the log is dropped
  // from the production bundle rather than firing on every visitor's page load.
  if (import.meta.env.DEV && ready && !wasReady) console.log('[pdfReady] __PDF_READY__ = true')
}

updateFlag()

// Call synchronously at the top of <script setup>, before onMounted, so it
// registers before anything can race past it. Call the returned callback once
// the component's async work is done (e.g. MapLibre's 'idle' after tiles load).
export function registerPendingRender(): () => void {
  const token = Symbol()
  pending.add(token)
  updateFlag()

  return () => {
    pending.delete(token)
    updateFlag()
  }
}

export function markIslandScanComplete(): void {
  scanComplete = true
  updateFlag()
}
