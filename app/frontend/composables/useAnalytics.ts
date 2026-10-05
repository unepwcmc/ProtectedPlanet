// Non-essential tracking, gated on cookie consent — nothing here runs until
// the user has explicitly accepted. CookieConsent.vue calls
// acceptAnalytics()/rejectAnalytics(); application.ts calls initAnalytics() on
// every page load to resume tracking for visitors who already opted in.
import { getConsent, setConsent } from '@/lib/cookieConsent'
import useEnv from '@/composables/useEnvs'
import { Environment } from '@/constants/environment'
import {
  ConsentStatus,
  GA_MEASUREMENT_ID_PRODUCTION,
  GA_MEASUREMENT_ID_STAGING,
  HOTJAR_ID,
  HOTJAR_SNIPPET_VERSION
} from '@/constants/analytics'

declare global {
  interface Window {
    dataLayer?: unknown[][]
    gtag?: (...args: unknown[]) => void
  }
}

interface HotjarWindow extends Window {
  hj?: ((...args: unknown[]) => void) & { q?: unknown[] }
  _hjSettings?: { hjid: number, hjsv: number }
}

// Shared across every useAnalytics() call: the scripts must load at most once
// per page however many components call in.
let optionalScriptsLoaded = false

function loadHotjar() {
  const h = window as HotjarWindow

  h.hj = h.hj || function (...args: unknown[]) {
    (h.hj!.q = h.hj!.q || []).push(args)
  }
  h._hjSettings = { hjid: HOTJAR_ID, hjsv: HOTJAR_SNIPPET_VERSION }

  const script = document.createElement('script')
  script.async = true
  script.src = `https://static.hotjar.com/c/hotjar-${HOTJAR_ID}.js?sv=${HOTJAR_SNIPPET_VERSION}`
  document.head.appendChild(script)
}

export default function () {
  const env = useEnv()

  function getGaMeasurementId(): string {
    switch (env.VITE_RAILS_ENV) {
      case Environment.Staging: return GA_MEASUREMENT_ID_STAGING
      case Environment.Production: return GA_MEASUREMENT_ID_PRODUCTION
      default: return ''
    }
  }

  function loadGoogleAnalytics() {
    const measurementId = getGaMeasurementId()
    if (!measurementId) return

    window.dataLayer = window.dataLayer || []
    window.gtag = function gtag(...args: unknown[]) {
      window.dataLayer!.push(args)
    }
    window.gtag('js', new Date())
    // No send_page_view override needed: every navigation is a full document
    // load, so this runs once per page view and gtag's automatic page_view is
    // already exactly one per page.
    window.gtag('config', measurementId)

    const script = document.createElement('script')
    script.async = true
    script.src = `https://www.googletagmanager.com/gtag/js?id=${measurementId}`
    document.head.appendChild(script)
  }

  function loadOptionalScripts() {
    if (optionalScriptsLoaded) return
    optionalScriptsLoaded = true

    loadGoogleAnalytics()
    loadHotjar()
  }

  function acceptAnalytics(): void {
    setConsent(ConsentStatus.Granted)
    loadOptionalScripts()
  }

  function rejectAnalytics(): void {
    setConsent(ConsentStatus.Denied)
  }

  function initAnalytics(): void {
    if (getConsent() === ConsentStatus.Granted) loadOptionalScripts()
  }

  function trackEvent(action: string, params: Record<string, unknown> = {}): void {
    window.gtag?.('event', action, params)
  }

  return { acceptAnalytics, rejectAnalytics, initAnalytics, trackEvent }
}
