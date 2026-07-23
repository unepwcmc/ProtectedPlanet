import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import FilterGroup from '@/components/Listing/FilterGroup.vue'

const filter = {
  id: 'topics',
  title: 'Topics',
  type: 'checkbox' as const,
  options: [
    { id: 'wdpa', title: 'WDPA' },
    { id: 'oecm', title: 'OECM' }
  ]
}

describe('Listing FilterGroup', () => {
  it('emits update:filter with the filter id and selected options on change', async () => {
    const wrapper = mount(FilterGroup, { props: { filter, textClear: 'Clear' } })

    await wrapper.find('input[value="wdpa"]').setValue(true)

    expect(wrapper.emitted('update:filter')?.at(-1)).toEqual([{ id: 'topics', options: ['wdpa'] }])
  })

  it('primes the parent with a preSelected value on mount', () => {
    const wrapper = mount(FilterGroup, { props: { filter, preSelected: ['oecm'], textClear: 'Clear' } })

    expect(wrapper.emitted('update:filter')?.[0]).toEqual([{ id: 'topics', options: ['oecm'] }])
  })

  it('does not emit on mount when there is no preSelected value', () => {
    const wrapper = mount(FilterGroup, { props: { filter, textClear: 'Clear' } })

    expect(wrapper.emitted('update:filter')).toBeUndefined()
  })

  it('clears the checkboxes when the clear button is clicked', async () => {
    const wrapper = mount(FilterGroup, { props: { filter, preSelected: ['wdpa'], textClear: 'Clear' } })

    await wrapper.find('.filter__button-clear').trigger('click')

    expect((wrapper.find('input[value="wdpa"]').element as HTMLInputElement).checked).toBe(false)
  })
})
