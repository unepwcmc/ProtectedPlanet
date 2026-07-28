import { describe, it, expect, beforeEach } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { usePameStore } from '@/stores/usePameStore'

beforeEach(() => {
  setActivePinia(createPinia())
})

describe('usePameStore', () => {
  it('starts with the same defaults as the legacy Vuex module', () => {
    const store = usePameStore()

    expect(store.requestedPage).toBe(1)
    expect(store.selectedFilterOptions).toEqual([])
    expect(store.modalContent).toBeNull()
    expect(store.isModalOpen).toBe(false)
    expect(store.isFetching).toBe(false)
  })

  it('setFetching toggles the one shared in-flight flag', () => {
    const store = usePameStore()

    store.setFetching(true)
    expect(store.isFetching).toBe(true)

    store.setFetching(false)
    expect(store.isFetching).toBe(false)
  })

  it('updates only the named filter, leaving the others untouched', () => {
    const store = usePameStore()
    store.setFilterOptions([
      { name: 'method', options: [] },
      { name: 'country', options: [] }
    ])

    store.updateFilterOptions('country', ['Kenya'])

    expect(store.selectedFilterOptions).toEqual([
      { name: 'method', options: [] },
      { name: 'country', options: ['Kenya'] }
    ])
  })

  it('opens the modal with the given item and closes it independently of modalContent', () => {
    const store = usePameStore()
    const item = { id: 1, name: 'Test Area' } as never

    store.openModal(item)

    expect(store.isModalOpen).toBe(true)
    expect(store.modalContent).toEqual(item)

    store.closeModal()

    expect(store.isModalOpen).toBe(false)
    expect(store.modalContent).toEqual(item)
  })
})
