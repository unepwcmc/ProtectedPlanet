import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import FiltersGroup from '@/components/Filters/Group.vue'

const options = [
  { id: 'wdpa', title: 'WDPA' },
  { id: 'oecm', title: 'OECM' }
]

// Comfy::Cms::PageCategory#id is numeric, unlike the search-areas string ids.
const numericOptions = [
  { id: 1, title: 'News' },
  { id: 2, title: 'Reports' }
]

describe('FiltersGroup', () => {
  describe('checkbox', () => {
    it('emits update:filter with the filter id and selected options on change', async () => {
      const wrapper = mount(FiltersGroup, {
        props: { id: 'db_type', type: 'checkbox', options, textClear: 'Clear' }
      })

      await wrapper.find('input[value="wdpa"]').setValue(true)

      expect(wrapper.emitted('update:filter')?.at(-1)).toEqual([{ id: 'db_type', options: ['wdpa'] }])
    })

    it('emits numeric CMS category ids unchanged', async () => {
      const wrapper = mount(FiltersGroup, {
        props: { id: 'topics', type: 'checkbox', options: numericOptions, textClear: 'Clear' }
      })

      await wrapper.find('input[value="1"]').setValue(true)

      expect(wrapper.emitted('update:filter')?.at(-1)).toEqual([{ id: 'topics', options: [1] }])
    })

    it('primes the parent with a preSelected value on mount', () => {
      const wrapper = mount(FiltersGroup, {
        props: { id: 'db_type', type: 'checkbox', options, preSelected: ['oecm'], textClear: 'Clear' }
      })

      expect(wrapper.emitted('update:filter')?.[0]).toEqual([{ id: 'db_type', options: ['oecm'] }])
    })

    it('does not emit on mount when there is no preSelected value', () => {
      const wrapper = mount(FiltersGroup, {
        props: { id: 'db_type', type: 'checkbox', options, textClear: 'Clear' }
      })

      expect(wrapper.emitted('update:filter')).toBeUndefined()
    })

    it('clears the checkboxes when the clear button is clicked', async () => {
      const wrapper = mount(FiltersGroup, {
        props: { id: 'db_type', type: 'checkbox', options, preSelected: ['wdpa'], textClear: 'Clear' }
      })

      await wrapper.find('.ct-filters-group__clear').trigger('click')

      expect((wrapper.find('input[value="wdpa"]').element as HTMLInputElement).checked).toBe(false)
    })

    it('clears on the page-wide resetKey as well as its own clear button', async () => {
      const wrapper = mount(FiltersGroup, {
        props: { id: 'db_type', type: 'checkbox', options, preSelected: ['wdpa'], resetKey: 0, textClear: 'Clear' }
      })

      await wrapper.setProps({ resetKey: 1 })

      expect(wrapper.emitted('update:filter')?.at(-1)).toEqual([{ id: 'db_type', options: [] }])
    })
  })

  describe('radio', () => {
    it('wraps a single selected radio value in an array', async () => {
      const wrapper = mount(FiltersGroup, {
        props: { id: 'sort', type: 'radio', name: 'sort', options, textClear: 'Clear' }
      })

      await wrapper.find('input[value="oecm"]').trigger('click')

      expect(wrapper.emitted('update:filter')?.at(-1)).toEqual([{ id: 'sort', options: ['oecm'] }])
    })

    it('primes the parent with a flat array, not a nested one', () => {
      const wrapper = mount(FiltersGroup, {
        props: { id: 'sort', type: 'radio', name: 'sort', options, preSelected: ['oecm'], textClear: 'Clear' }
      })

      expect(wrapper.emitted('update:filter')?.at(-1)).toEqual([{ id: 'sort', options: ['oecm'] }])
    })
  })

  describe('checkbox-search', () => {
    const locationOptions = [
      { id: 'country', title: 'Country', autocomplete: [{ id: 'FRA', title: 'France' }] },
      { id: 'region', title: 'Region', autocomplete: [{ id: 'EUR', title: 'Europe' }] }
    ]

    it('emits a {type, options} payload', async () => {
      const wrapper = mount(FiltersGroup, {
        props: { id: 'location', type: 'checkbox-search', name: 'location', options: locationOptions, textClear: 'Clear' }
      })

      await wrapper.find('input[value="FRA"]').setValue(true)

      expect(wrapper.emitted('update:filter')?.at(-1)).toEqual([{ id: 'location', options: { type: 'country', options: ['FRA'] } }])
    })

    it('primes the parent from the single preSelected entry', () => {
      const wrapper = mount(FiltersGroup, {
        props: {
          id: 'location',
          type: 'checkbox-search',
          name: 'location',
          options: locationOptions,
          preSelected: [{ type: 'region', options: ['EUR'] }] as [{ type: string, options: string[] }],
          textClear: 'Clear'
        }
      })

      expect(wrapper.emitted('update:filter')?.[0]).toEqual([{ id: 'location', options: { type: 'region', options: ['EUR'] } }])
    })
  })

  it('omits the title when the filter has none', () => {
    const wrapper = mount(FiltersGroup, {
      props: { id: 'db_type', type: 'checkbox', options, textClear: 'Clear' }
    })

    expect(wrapper.find('.ct-filters-group__title').exists()).toBe(false)
  })
})
