// Forces a real browser navigation for Turbo Drive visits that come back with
// an error status, instead of letting Turbo render the error page in place.
//
// Why: a non-2xx response takes a completely different render path inside
// Turbo. Visit#loadResponse routes it to PageView#renderError -> ErrorRenderer,
// whose replaceHeadAndBody() does
//     documentElement.replaceChild(this.newHead, head)
// i.e. it THROWS THE WHOLE <head> AWAY and installs the one parsed out of the
// error response's HTML. The normal PageRenderer merges heads and deliberately
// preserves existing <style>/<link rel=stylesheet> elements; ErrorRenderer does
// not.
//
// So the only CSS surviving an error render is what Rails actually printed into
// the head (vite_stylesheet_tag 'vitecss.css' -- Tailwind + the vw-* block
// styles). Everything injected at RUNTIME by JS is destroyed:
//   * dev  -- every SFC <style> block, which Vite's client appends to
//             document.head as <style data-vite-dev-id> (its updateStyle()).
//   * prod -- the <link>s __vitePreload injects for lazily-imported component
//             chunks (on layouts/error_page that's CarouselThemes,
//             ListingPageCardNews, ListingPageCardResources).
// Nothing puts them back either: application.ts is already evaluated, Vite's
// sheetsMap/seen caches still hold the now-detached nodes, and ErrorRenderer
// re-inserting an identical <script type="module" src="..."> does not
// re-execute an already-loaded module. Result: the error page renders with all
// Vue component styles missing, and only a manual refresh (a fresh document,
// so the module graph re-runs) fixes it.
//
// turbo:before-fetch-response is dispatched cancelable, and preventDefault on
// it stops Turbo handling the response at all -- so we hand the URL to the
// browser and get a clean full load. Costs one extra request, but only on an
// actual error page, and it leaves the URL/history correct as a bonus.

interface TurboFetchResponseEventDetail {
  fetchResponse: {
    contentType?: string
    response: Response
  }
}

// 422 is Rails' "re-render the form with validation errors" status: that
// response body IS the thing to display, and reloading would GET the page
// afresh and lose it. Turbo must keep handling those itself.
const UNPROCESSABLE_ENTITY = 422
const TURBO_STREAM_CONTENT_TYPE = 'text/vnd.turbo-stream.html'

function handleErrorResponse(event: Event): void {
  const { fetchResponse } = (event as CustomEvent<TurboFetchResponseEventDetail>).detail
  if (!fetchResponse) return

  const { status, url } = fetchResponse.response
  if (status < 400 || status === UNPROCESSABLE_ENTITY) return
  // Stream responses are applied to the current page rather than rendered as
  // one, so they never reach ErrorRenderer and must be left alone.
  if (fetchResponse.contentType?.startsWith(TURBO_STREAM_CONTENT_TYPE)) return
  if (!url) return

  event.preventDefault()
  window.location.href = url
}

export function installTurboErrorResponseHandler(): void {
  document.addEventListener('turbo:before-fetch-response', handleErrorResponse)
}

export function uninstallTurboErrorResponseHandler(): void {
  document.removeEventListener('turbo:before-fetch-response', handleErrorResponse)
}
