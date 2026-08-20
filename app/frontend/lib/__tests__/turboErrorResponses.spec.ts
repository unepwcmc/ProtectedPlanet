import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import {
  installTurboErrorResponseHandler,
  uninstallTurboErrorResponseHandler
} from '@/lib/turboErrorResponses'

const PAGE_URL = 'https://example.test/some/page'

// Mirrors the shape Turbo puts on the event: a FetchResponse wrapper around a
// real Response, plus the parsed content type.
function dispatchFetchResponse({
  status,
  contentType = 'text/html; charset=utf-8',
  url = PAGE_URL
}: { status: number, contentType?: string, url?: string }): CustomEvent {
  const event = new CustomEvent('turbo:before-fetch-response', {
    cancelable: true,
    detail: {
      fetchResponse: {
        contentType,
        // jsdom's Response constructor rejects a body/url combo we don't need
        // here, so a minimal stand-in keeps the test to the two fields the
        // handler actually reads.
        response: { status, url }
      }
    }
  })
  document.dispatchEvent(event)
  return event
}

let assignedHref: string | undefined

beforeEach(() => {
  assignedHref = undefined
  // jsdom refuses a real navigation; swap the whole location object so the
  // handler's `window.location.href = url` is observable instead of throwing.
  Object.defineProperty(window, 'location', {
    configurable: true,
    value: {
      get href() { return PAGE_URL },
      set href(value: string) { assignedHref = value }
    }
  })
  installTurboErrorResponseHandler()
})

afterEach(() => {
  uninstallTurboErrorResponseHandler()
  vi.restoreAllMocks()
})

describe('turboErrorResponses', () => {
  it('cancels Turbo and full-loads the URL for a 404', () => {
    const event = dispatchFetchResponse({ status: 404 })

    expect(event.defaultPrevented).toBe(true)
    expect(assignedHref).toBe(PAGE_URL)
  })

  it('cancels Turbo and full-loads the URL for a 500', () => {
    const event = dispatchFetchResponse({ status: 500 })

    expect(event.defaultPrevented).toBe(true)
    expect(assignedHref).toBe(PAGE_URL)
  })

  it('leaves successful responses to Turbo', () => {
    const event = dispatchFetchResponse({ status: 200 })

    expect(event.defaultPrevented).toBe(false)
    expect(assignedHref).toBeUndefined()
  })

  // Rails re-renders a form with validation errors as 422; reloading would GET
  // the page afresh and throw that body away.
  it('leaves 422 to Turbo so form error re-renders still work', () => {
    const event = dispatchFetchResponse({ status: 422 })

    expect(event.defaultPrevented).toBe(false)
    expect(assignedHref).toBeUndefined()
  })

  it('leaves turbo-stream responses to Turbo even on an error status', () => {
    const event = dispatchFetchResponse({
      status: 500,
      contentType: 'text/vnd.turbo-stream.html; charset=utf-8'
    })

    expect(event.defaultPrevented).toBe(false)
    expect(assignedHref).toBeUndefined()
  })

  it('stops handling once uninstalled', () => {
    uninstallTurboErrorResponseHandler()

    const event = dispatchFetchResponse({ status: 500 })

    expect(event.defaultPrevented).toBe(false)
    expect(assignedHref).toBeUndefined()
  })
})
