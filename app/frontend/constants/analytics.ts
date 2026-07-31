export enum ConsentStatus {
  Granted = 'granted',
  Denied = 'denied'
}

export const CONSENT_COOKIE = 'cookie_consent'
export const CONSENT_MAX_AGE = 60 * 60 * 24 * 365 // 1 year

// GA4 measurement ids per Vite mode (see useAnalytics.ts, which picks the right
// one for import.meta.env.MODE) — dev/test have no id, so no real analytics load.
export const GA_MEASUREMENT_ID_STAGING = 'G-XVH7FS5FYK'
export const GA_MEASUREMENT_ID_PRODUCTION = 'G-6MKSEC2PEB'

export const HOTJAR_ID = 2001805
export const HOTJAR_SNIPPET_VERSION = 6
