import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { useDownloads, resetDownloads } from '@/composables/useDownloads'

const FIVE_DAYS_MS = 5 * 24 * 60 * 60 * 1000

function storedItems() {
  return JSON.parse(localStorage.getItem('downloadItems') as string)
}

// What another tab writing to localStorage looks like from in here.
function otherTabWrote(items: unknown) {
  const newValue = JSON.stringify(items)
  localStorage.setItem('downloadItems', newValue)
  window.dispatchEvent(new StorageEvent('storage', {
    key: 'downloadItems',
    newValue,
    storageArea: localStorage
  }))
}

beforeEach(() => {
  localStorage.clear()
  sessionStorage.clear()
  resetDownloads()
})

afterEach(() => {
  vi.useRealTimers()
})

describe('useDownloads', () => {
  it('starts with empty state', () => {
    const store = useDownloads()

    expect(store.downloadItems).toEqual([])
    expect(store.isModalActive).toBe(false)
    expect(store.isModalMinimised).toBe(false)
    expect(store.searchFilters).toEqual([])
    expect(store.searchTerm).toBe('')
  })

  describe('adding an item', () => {
    it('opens the modal and assigns a unique id', () => {
      const store = useDownloads()

      const item = store.addNewDownloadItem({ domain: 'protected_area', format: 'csv', token: 'abc' })

      expect(store.downloadItems).toEqual([item])
      expect(item.id).toMatch(/^[0-9a-f-]{36}$/)
      expect(item.createdAt).toBeGreaterThan(0)
      expect(store.isModalActive).toBe(true)
      expect(store.isModalMinimised).toBe(false)
    })

    it('stores only what identifies the download, never its status', () => {
      const store = useDownloads()

      const item = store.addNewDownloadItem({ domain: 'protected_area', format: 'csv', token: 'abc' })

      expect(Object.keys(item).sort()).toEqual(['createdAt', 'domain', 'format', 'id', 'token'])
    })

    it('gives two identical-looking requests different ids only when they are not duplicates', () => {
      const store = useDownloads()

      const csv = store.addNewDownloadItem({ domain: 'protected_area', format: 'csv', token: 'abc' })
      const shp = store.addNewDownloadItem({ domain: 'protected_area', format: 'shp', token: 'abc' })

      expect(csv.id).not.toBe(shp.id)
      expect(store.downloadItems).toHaveLength(2)
    })

    it('re-surfaces an existing identical request instead of generating it twice', () => {
      const store = useDownloads()
      const first = store.addNewDownloadItem({ domain: 'protected_area', format: 'csv', token: 'abc' })
      store.minimiseDownloadModal(true)

      const second = store.addNewDownloadItem({ domain: 'protected_area', format: 'csv', token: 'abc' })

      expect(second.id).toBe(first.id)
      expect(store.downloadItems).toHaveLength(1)
      expect(store.isModalMinimised).toBe(false)
    })

    it('attaches the search state a "search" download needs to be reproducible', () => {
      const store = useDownloads()
      store.updateSearchFilters([{ key: 'iucn_category', value: 'Ia' }])
      store.updateSearchTerm('coral reef')

      const item = store.addNewDownloadItem({ domain: 'search', format: 'csv', token: 'all' })

      expect(item.filters).toEqual([{ key: 'iucn_category', value: 'Ia' }])
      expect(item.search).toBe('coral reef')
    })

    it('treats the same search download under different filters as two downloads', () => {
      const store = useDownloads()
      store.updateSearchTerm('reef')
      store.addNewDownloadItem({ domain: 'search', format: 'csv', token: 'all' })

      store.updateSearchFilters([{ key: 'marine', value: 'true' }])
      store.addNewDownloadItem({ domain: 'search', format: 'csv', token: 'all' })

      expect(store.downloadItems).toHaveLength(2)
    })
  })

  it('patches a single item by id', () => {
    const store = useDownloads()
    const item = store.addNewDownloadItem({ domain: 'search', format: 'csv', token: 'all' })
    const other = store.addNewDownloadItem({ domain: 'protected_area', format: 'shp', token: 'abc' })

    store.patchDownloadItem(item.id, { backEndToken: 'digest' })

    expect(store.downloadItems[0]).toMatchObject({ backEndToken: 'digest' })
    expect(store.downloadItems[1]).toEqual(other)
  })

  describe('who may ask the server to generate a file', () => {
    it('lets the click that requested the download create it, once', () => {
      const store = useDownloads()

      const item = store.addNewDownloadItem({ domain: 'protected_area', format: 'csv', token: 'abc' })

      expect(store.consumeCreateRequest(item.id)).toBe(true)
      expect(store.consumeCreateRequest(item.id)).toBe(false)
    })

    it('refuses an item this page load did not request — a reload or another tab', () => {
      localStorage.setItem('downloadItems', JSON.stringify([
        { id: 'from-elsewhere', domain: 'general', format: 'csv', token: 'wdpa', createdAt: Date.now() }
      ]))

      const store = useDownloads()

      expect(store.consumeCreateRequest('from-elsewhere')).toBe(false)
    })

    it('refuses a duplicate request, which re-surfaces the existing row instead', () => {
      const store = useDownloads()
      const first = store.addNewDownloadItem({ domain: 'protected_area', format: 'csv', token: 'abc' })
      store.consumeCreateRequest(first.id)

      const second = store.addNewDownloadItem({ domain: 'protected_area', format: 'csv', token: 'abc' })

      expect(second.id).toBe(first.id)
      expect(store.consumeCreateRequest(second.id)).toBe(false)
    })
  })

  it('deletes an item by id', () => {
    const store = useDownloads()
    const first = store.addNewDownloadItem({ domain: 'protected_area', format: 'csv', token: 'a' })
    store.addNewDownloadItem({ domain: 'protected_area', format: 'shp', token: 'b' })

    store.deleteDownloadItem(first)

    expect(store.downloadItems).toHaveLength(1)
    expect(store.downloadItems[0].format).toBe('shp')
  })

  it('toggles and minimises the modal independently', () => {
    const store = useDownloads()

    store.toggleDownloadModal(true)
    expect(store.isModalActive).toBe(true)
    store.minimiseDownloadModal(true)
    expect(store.isModalMinimised).toBe(true)
    store.toggleDownloadModal(false)
    expect(store.isModalActive).toBe(false)
    expect(store.isModalMinimised).toBe(true)
  })

  describe('persistence', () => {
    it('writes the item list through to localStorage without waiting for unload', () => {
      const store = useDownloads()

      store.addNewDownloadItem({ domain: 'protected_area', format: 'csv', token: 'abc' })

      expect(storedItems()).toEqual(store.downloadItems)
    })

    it('persists a change made in the same tick as another', () => {
      const store = useDownloads()

      const item = store.addNewDownloadItem({ domain: 'search', format: 'csv', token: 'all' })
      store.patchDownloadItem(item.id, { backEndToken: 'digest' })

      expect(storedItems()[0].backEndToken).toBe('digest')
    })

    it('drops a status a previous version of the app persisted', () => {
      localStorage.setItem('downloadItems', JSON.stringify([
        { id: 'a', domain: 'general', format: 'csv', token: 'wdpa', createdAt: Date.now(), url: '/files/stale.csv', title: 'stale.csv', hasFailed: false }
      ]))

      const store = useDownloads()

      expect(store.downloadItems[0]).not.toHaveProperty('url')
      expect(store.downloadItems[0]).not.toHaveProperty('title')
      expect(store.downloadItems[0]).not.toHaveProperty('hasFailed')
    })

    it('keeps modal chrome per-tab in sessionStorage, and clears the keys it used to leave in localStorage', () => {
      localStorage.setItem('isModalActive', 'true')
      localStorage.setItem('isModalMinimised', 'true')

      const store = useDownloads()
      store.minimiseDownloadModal(true)

      expect(sessionStorage.getItem('isModalMinimised')).toBe('true')
      expect(localStorage.getItem('isModalActive')).toBeNull()
      expect(localStorage.getItem('isModalMinimised')).toBeNull()
    })

    it('restores persisted items on load', () => {
      localStorage.setItem('downloadItems', JSON.stringify([
        { id: 'a', domain: 'protected_area', format: 'pdf', token: 'z', createdAt: Date.now() }
      ]))

      const store = useDownloads()

      expect(store.downloadItems).toHaveLength(1)
      expect(store.downloadItems[0]).toMatchObject({ id: 'a', format: 'pdf', token: 'z' })
    })

    it('adopts a legacy item written before ids were strings', () => {
      localStorage.setItem('downloadItems', JSON.stringify([
        { id: 42, domain: 'protected_area', format: 'csv', token: 'z' }
      ]))

      const store = useDownloads()

      expect(store.downloadItems[0].id).toBe('42')
      expect(store.downloadItems[0].createdAt).toBeGreaterThan(0)
    })

    it('drops items older than five days', () => {
      const now = Date.now()
      localStorage.setItem('downloadItems', JSON.stringify([
        { id: 'stale', domain: 'general', format: 'csv', token: 'wdpa', createdAt: now - FIVE_DAYS_MS - 1 },
        { id: 'fresh', domain: 'general', format: 'csv', token: 'marine', createdAt: now - 1000 }
      ]))

      const store = useDownloads()

      expect(store.downloadItems.map(item => item.id)).toEqual(['fresh'])
      // The pruned list is written back, not just held in memory.
      expect(storedItems().map((item: { id: string }) => item.id)).toEqual(['fresh'])
    })

    it('caps the list, keeping the newest entries', () => {
      const now = Date.now()
      localStorage.setItem('downloadItems', JSON.stringify(
        Array.from({ length: 25 }, (_, index) => ({
          id: `item-${index}`, domain: 'general', format: 'csv', token: `t${index}`, createdAt: now
        }))
      ))

      const store = useDownloads()

      expect(store.downloadItems).toHaveLength(20)
      expect(store.downloadItems[0].id).toBe('item-5')
    })

    it('falls back to an empty list when the stored value is corrupt', () => {
      localStorage.setItem('downloadItems', 'not-json')
      const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

      const store = useDownloads()

      expect(store.downloadItems).toEqual([])
      expect(errorSpy).toHaveBeenCalled()
      errorSpy.mockRestore()
    })

    it('falls back to an empty list when the stored value parses but is not an array', () => {
      localStorage.setItem('downloadItems', '"a string"')

      const store = useDownloads()

      expect(store.downloadItems).toEqual([])
    })

    it('drops entries that are not shaped like a download', () => {
      localStorage.setItem('downloadItems', JSON.stringify([
        null,
        'nope',
        { domain: 'general', format: 'csv' },
        { id: 'ok', domain: 'general', format: 'csv', token: 'wdpa', createdAt: Date.now() }
      ]))

      const store = useDownloads()

      expect(store.downloadItems.map(item => item.id)).toEqual(['ok'])
    })
  })

  describe('cross-tab syncing', () => {
    it('picks up an item another tab requested', () => {
      const store = useDownloads()

      otherTabWrote([
        { id: 'from-b', domain: 'general', format: 'csv', token: 'wdpa', createdAt: Date.now() }
      ])

      expect(store.downloadItems.map(item => item.id)).toEqual(['from-b'])
    })

    it('picks up a deletion in another tab', () => {
      const store = useDownloads()
      store.addNewDownloadItem({ domain: 'general', format: 'csv', token: 'wdpa' })

      otherTabWrote([])

      expect(store.downloadItems).toEqual([])
    })

    it('validates what another tab wrote, rather than trusting it', () => {
      const store = useDownloads()

      otherTabWrote([{ nonsense: true }])

      expect(store.downloadItems).toEqual([])
    })
  })
})
