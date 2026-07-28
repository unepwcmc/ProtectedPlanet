import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PameFilters from '@/components/Pame/Filters/Index.vue'
import { usePameStore } from '@/stores/usePameStore'

const filters = [
  { name: 'method', title: 'Method', options: ['Aerial survey'], type: 'multiple' },
  { name: 'country', title: 'Country', options: ['Kenya'], type: 'multiple' },
  { name: 'empty', title: 'Empty', options: [], type: 'multiple' }
]

beforeEach(() => {
  setActivePinia(createPinia())
})

describe('Pame Filters Index', () => {
  it('primes the store with one empty entry per real filter on mount', () => {
    mount(PameFilters, { props: { filters, totalItems: 10 } })
    const store = usePameStore()

    expect(store.selectedFilterOptions).toEqual([
      { name: 'method', options: [], type: 'multiple' },
      { name: 'country', options: [], type: 'multiple' }
    ])
  })

  it('only shows one filter dropdown open at a time', async () => {
    const wrapper = mount(PameFilters, { props: { filters, totalItems: 10 } })
    const buttons = wrapper.findAll('.filter__button')

    await buttons[0].trigger('click')
    expect(wrapper.findAll('.filter__options--active')).toHaveLength(1)

    await buttons[1].trigger('click')
    const activeOptions = wrapper.findAll('.filter__options--active')
    expect(activeOptions).toHaveLength(1)
  })

  it('applying a filter updates the store, resets to page 1, and requests items', async () => {
    const wrapper = mount(PameFilters, { props: { filters, totalItems: 10 } })
    const store = usePameStore()
    store.updateRequestedPage(3)

    const countryFilter = wrapper.findAll('.filter')[1]
    await countryFilter.find('.filter__button').trigger('click')
    await countryFilter.find('.filter__checkbox').setValue(true)
    await countryFilter.find('.filter__button-apply').trigger('click')

    expect(store.selectedFilterOptions.find(f => f.name === 'country')?.options).toEqual(['Kenya'])
    expect(store.requestedPage).toBe(1)
    expect(wrapper.emitted('requestItems')).toHaveLength(1)
  })
})
