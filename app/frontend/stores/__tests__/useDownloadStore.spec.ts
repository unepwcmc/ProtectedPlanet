import { describe, it, expect, beforeEach, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useDownloadStore } from '@/stores/useDownloadStore'

beforeEach(() => {
  setActivePinia(createPinia())
  localStorage.clear()
})

describe('useDownloadStore', () => {
  it('starts with the same defaults as the legacy Vuex module', () => {
    const store = useDownloadStore()

    expect(store.downloadItems).toEqual([])
    expect(store.isModalActive).toBe(false)
    expect(store.isModalMinimised).toBe(false)
    expect(store.searchFilters).toEqual([])
    expect(store.searchTerm).toBe('')
  })

  it('adding a download item also opens and maximises the modal', () => {
    const store = useDownloadStore()

    store.addNewDownloadItem({ id: 1, domain: 'protected_area', format: 'csv', token: 'abc' })

    expect(store.downloadItems).toEqual([{ id: 1, domain: 'protected_area', format: 'csv', token: 'abc' }])
    expect(store.isModalActive).toBe(true)
    expect(store.isModalMinimised).toBe(false)
  })

  it('deletes a download item by id', () => {
    const store = useDownloadStore()
    store.addNewDownloadItem({ id: 1, domain: 'protected_area', format: 'csv', token: 'a' })
    store.addNewDownloadItem({ id: 2, domain: 'protected_area', format: 'shp', token: 'b' })

    store.deleteDownloadItem({ id: 1, domain: 'protected_area', format: 'csv', token: 'a' })

    expect(store.downloadItems).toEqual([{ id: 2, domain: 'protected_area', format: 'shp', token: 'b' }])
  })

  it('toggles and minimises the modal independently', () => {
    const store = useDownloadStore()

    store.toggleDownloadModal(true)
    expect(store.isModalActive).toBe(true)
    store.toggleDownloadModal(false)
    expect(store.isModalActive).toBe(false)

    store.minimiseDownloadModal(true)
    expect(store.isModalMinimised).toBe(true)
    store.minimiseDownloadModal(false)
    expect(store.isModalMinimised).toBe(false)
  })

  it('updates search filters and search term (for Download.vue\'s "search" domain option)', () => {
    const store = useDownloadStore()

    store.updateSearchFilters([{ key: 'iucn_category', value: 'Ia' }])
    store.updateSearchTerm('coral reef')

    expect(store.searchFilters).toEqual([{ key: 'iucn_category', value: 'Ia' }])
    expect(store.searchTerm).toBe('coral reef')
  })

  describe('localStorage persistence', () => {
    it('updateLocalStorage writes all three persisted keys', () => {
      const store = useDownloadStore()
      store.addNewDownloadItem({ id: 1, domain: 'protected_area', format: 'csv', token: 'a' })
      store.minimiseDownloadModal(true)

      store.updateLocalStorage()

      expect(JSON.parse(localStorage.getItem('downloadItems') as string)).toEqual(store.downloadItems)
      expect(localStorage.getItem('isModalActive')).toBe('true')
      expect(localStorage.getItem('isModalMinimised')).toBe('true')
    })

    it('initialiseStore restores state from localStorage', () => {
      localStorage.setItem('downloadItems', JSON.stringify([{ id: 9, domain: 'protected_area', format: 'pdf', token: 'z' }]))
      localStorage.setItem('isModalActive', 'true')
      localStorage.setItem('isModalMinimised', 'true')

      const store = useDownloadStore()
      store.initialiseStore()

      expect(store.downloadItems).toEqual([{ id: 9, domain: 'protected_area', format: 'pdf', token: 'z' }])
      expect(store.isModalActive).toBe(true)
      expect(store.isModalMinimised).toBe(true)
    })

    it('leaves defaults untouched when nothing is persisted yet', () => {
      const store = useDownloadStore()
      store.initialiseStore()

      expect(store.downloadItems).toEqual([])
      expect(store.isModalActive).toBe(false)
      expect(store.isModalMinimised).toBe(false)
    })

    it('a corrupt downloadItems value resets only that key, matching the legacy per-key catch', () => {
      localStorage.setItem('downloadItems', 'not-json')
      localStorage.setItem('isModalActive', 'true')
      const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

      const store = useDownloadStore()
      store.initialiseStore()

      expect(store.downloadItems).toEqual([])
      expect(store.isModalActive).toBe(true)
      expect(errorSpy).toHaveBeenCalled()

      errorSpy.mockRestore()
    })

    it('a corrupt isModalMinimised value resets it to true (minimised), matching the legacy catch', () => {
      localStorage.setItem('isModalMinimised', 'not-json')
      const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

      const store = useDownloadStore()
      store.initialiseStore()

      expect(store.isModalMinimised).toBe(true)

      errorSpy.mockRestore()
    })
  })
})
