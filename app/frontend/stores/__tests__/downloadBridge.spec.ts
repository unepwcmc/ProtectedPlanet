import { describe, it, expect, beforeEach } from 'vitest'
import { setActivePinia } from 'pinia'
import { installDownloadStoreBridge } from '@/stores/downloadBridge'
import { useDownloadStore } from '@/stores/useDownloadStore'
import { pinia } from '@/stores/pinia'

beforeEach(() => {
  setActivePinia(pinia)
  pinia.state.value = {}
})

describe('downloadBridge', () => {
  it('exposes window.__downloadStoreBridge writing into the shared Pinia download store', () => {
    installDownloadStoreBridge()

    window.__downloadStoreBridge?.updateSearchFilters([{ key: 'iucn_category', value: 'Ia' }])
    window.__downloadStoreBridge?.updateSearchTerm('coral reef')

    const store = useDownloadStore(pinia)
    expect(store.searchFilters).toEqual([{ key: 'iucn_category', value: 'Ia' }])
    expect(store.searchTerm).toBe('coral reef')
  })

  it('lets the legacy search_areas Download.vue add an item the migrated DownloadModal island will see', () => {
    installDownloadStoreBridge()

    window.__downloadStoreBridge?.addNewDownloadItem({ id: 1, domain: 'search', format: 'csv', token: 'abc' })

    const store = useDownloadStore(pinia)
    expect(store.downloadItems).toEqual([{ id: 1, domain: 'search', format: 'csv', token: 'abc' }])
    expect(store.isModalActive).toBe(true)
  })

  it('lets the legacy Download.vue read back searchFilters/searchTerm written by SearchAreas.vue', () => {
    installDownloadStoreBridge()

    window.__downloadStoreBridge?.updateSearchFilters([{ key: 'iucn_category', value: 'Ia' }])
    window.__downloadStoreBridge?.updateSearchTerm('coral reef')

    expect(window.__downloadStoreBridge?.getSearchFilters()).toEqual([{ key: 'iucn_category', value: 'Ia' }])
    expect(window.__downloadStoreBridge?.getSearchTerm()).toBe('coral reef')
  })
})
