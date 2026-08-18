// Cookie-consent status storage. Pure — reading or writing the consent value
// here has no side effects on tracking scripts. See composables/useAnalytics.ts for the
// code that reacts to consent and loads GA4/Hotjar, and the CookieConsent
// island (app/frontend/components/CookieConsent.vue) for the UI that records
// the user's decision.
import { ConsentStatus, CONSENT_COOKIE, CONSENT_MAX_AGE } from '@/constants/analytics'

function readCookie(name: string): string | null {
  const match = document.cookie.match(new RegExp(`(?:^|; )${name}=([^;]*)`))
  return match ? decodeURIComponent(match[1]) : null
}

function writeCookie(name: string, value: string, maxAge: number) {
  document.cookie = `${name}=${value}; path=/; max-age=${maxAge}; samesite=lax`
}

export function getConsent(): ConsentStatus | null {
  const value = readCookie(CONSENT_COOKIE)
  return value === ConsentStatus.Granted || value === ConsentStatus.Denied ? value : null
}

export function setConsent(status: ConsentStatus): void {
  writeCookie(CONSENT_COOKIE, status, CONSENT_MAX_AGE)
}
