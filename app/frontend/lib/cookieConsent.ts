// Cookie-consent storage only — reading or writing here has no effect on any
// tracking script. useAnalytics.ts reacts to consent; CookieConsent.vue is the
// UI that records the decision.
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
