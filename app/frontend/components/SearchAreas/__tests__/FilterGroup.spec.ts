import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchAreasFilterGroup from '@/components/SearchAreas/FilterGroup.vue'

const checkboxOptions = [
  { id: 'wdpa', title: 'WDPA' },
  { id: 'oecm', title: 'OECM' }
]

describe('SearchAreasFilterGroup', () => {
  it('emits update:filter with the filter id and selected options on change (checkbox)', async () => {
    const wrapper = mount(SearchAreasFilterGroup, {
      props: { id: 'db_type', type: 'checkbox', options: checkboxOptions, textClear: 'Clear' }
    })

    await wrapper.find('input[value="wdpa"]').setValue(true)

    expect(wrapper.emitted('update:filter')?.at(-1)).toEqual([{ id: 'db_type', options: ['wdpa'] }])
  })

  it('primes the parent with a preSelected value on mount (checkbox)', () => {
    const wrapper = mount(SearchAreasFilterGroup, {
      props: { id: 'db_type', type: 'checkbox', options: checkboxOptions, preSelected: ['oecm'], textClear: 'Clear' }
    })

    expect(wrapper.emitted('update:filter')?.[0]).toEqual([{ id: 'db_type', options: ['oecm'] }])
  })

  it('does not emit on mount when there is no preSelected value', () => {
    const wrapper = mount(SearchAreasFilterGroup, {
      props: { id: 'db_type', type: 'checkbox', options: checkboxOptions, textClear: 'Clear' }
    })

    expect(wrapper.emitted('update:filter')).toBeUndefined()
  })

  it('clears the checkboxes when the clear button is clicked', async () => {
    const wrapper = mount(SearchAreasFilterGroup, {
      props: { id: 'db_type', type: 'checkbox', options: checkboxOptions, preSelected: ['wdpa'], textClear: 'Clear' }
    })

    await wrapper.find('.filter__button-clear').trigger('click')

    expect((wrapper.find('input[value="wdpa"]').element as HTMLInputElement).checked).toBe(false)
  })

  it('wraps a single selected radio value in an array (radio)', async () => {
    const wrapper = mount(SearchAreasFilterGroup, {
      props: { id: 'sort', type: 'radio', name: 'sort', options: checkboxOptions, textClear: 'Clear' }
    })

    await wrapper.find('input[value="oecm"]').trigger('click')

    expect(wrapper.emitted('update:filter')?.at(-1)).toEqual([{ id: 'sort', options: ['oecm'] }])
  })

  it('emits a {type, options} payload for a checkbox-search filter', async () => {
    const options = [
      { id: 'country', title: 'Country', autocomplete: [{ id: 'FRA', title: 'France' }] },
      { id: 'region', title: 'Region', autocomplete: [{ id: 'EUR', title: 'Europe' }] }
    ]
    const wrapper = mount(SearchAreasFilterGroup, {
      props: { id: 'location', type: 'checkbox-search', name: 'location', options, textClear: 'Clear' }
    })

    await wrapper.find('input[value="FRA"]').setValue(true)

    expect(wrapper.emitted('update:filter')?.at(-1)).toEqual([{ id: 'location', options: { type: 'country', options: ['FRA'] } }])
  })
})
