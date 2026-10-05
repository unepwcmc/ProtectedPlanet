import { JSDOM } from 'jsdom'

// Node defines its own `localStorage` global, left undefined unless the process
// was started with --localstorage-file. It shadows the one jsdom installs, which
// vitest then declines to copy onto globalThis, so hand the tests a real Storage.
if (!globalThis.localStorage) {
  const { localStorage } = new JSDOM('', { url: 'http://localhost' }).window

  Object.defineProperty(globalThis, 'localStorage', {
    value: localStorage,
    writable: true,
    configurable: true,
  })
}
