// GA4 event helper. gtag.js is not wired into the layout yet — analytics.js/UA is
// still what's loaded (see app/views/partials/_google_analytics.html.erb) and GA4
// migration is tracked separately (upgrade-plan/frontend/01-live-inventory.md). This
// no-ops until gtag.js lands, so islands can call it now and get real tracking for
// free the moment it does, instead of every component reaching for `window.gtag`.
declare global {
  interface Window {
    gtag?: (...args: unknown[]) => void
  }
}

export function trackEvent(action: string, params: Record<string, unknown> = {}): void {
  window.gtag?.('event', action, params)
}
