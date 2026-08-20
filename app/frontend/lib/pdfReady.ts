// Lets the PDF rasterizer (rasterize.js) wait for a real "the page is actually
// done rendering" signal instead of a fixed sleep. `window.__PDF_READY__` only
// flips true once every turbo-mount island's mount promise has settled
// (markIslandScanComplete, called from turboMount.ts) AND every component
// that does its own post-mount async work (data fetches, map tile loading)
// has told us it's finished (registerPendingRender's returned callback).
//
// Set eagerly (not left undefined) so a page with no async work still ends
// up with a defined `false` the instant this module runs, then `true` once
// the initial scan's promises resolve — a page whose bundle fails to load at
// all correctly leaves this undefined forever, which is exactly the "fail
// loudly rather than ship a broken PDF" behaviour rasterize.js wants.
const pending = new Set<symbol>()
let scanComplete = false

function updateFlag(): void {
  ;(window as unknown as { __PDF_READY__?: boolean }).__PDF_READY__ = scanComplete && pending.size === 0
}

updateFlag()

// Call at the top of a component's <script setup> (synchronously, before
// onMounted) so it's registered before anything can race past it, then call
// the returned callback once that component's own async work is truly done
// (e.g. MapLibre's 'idle' event after tiles finish loading).
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
