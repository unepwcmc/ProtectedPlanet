import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import PameFilters from '@/components/Pame/Filters/Index.vue'
import PameTableDownloadCsv from '@/components/Pame/Table/DownloadCsv.vue'

const filters = [
  { name: 'method', title: 'Method', options: ['Aerial survey'], type: 'multiple' },
  { name: 'country', title: 'Country', options: ['Kenya'], type: 'multiple' },
  { name: 'empty', title: 'Empty', options: [], type: 'multiple' }
]

const selectedFilterOptions = [
  { name: 'method', options: [], type: 'multiple' },
  { name: 'country', options: [], type: 'multiple' }
]

describe('Pame Filters Index', () => {
  it('only shows one filter dropdown open at a time', async () => {
    const wrapper = mount(PameFilters, { props: { filters, isFetching: false, selectedFilterOptions, totalItems: 10 } })
    const buttons = wrapper.findAll('.ct-pame-filter__button')

    await buttons[0].trigger('click')
    expect(wrapper.findAll('.ct-pame-filter-mobile--active')).toHaveLength(1)

    await buttons[1].trigger('click')
    const activeOptions = wrapper.findAll('.ct-pame-filter-mobile--active')
    expect(activeOptions).toHaveLength(1)
  })

  it('applying a filter emits its name and options to the parent, which owns the URL state', async () => {
    const wrapper = mount(PameFilters, { props: { filters, isFetching: false, selectedFilterOptions, totalItems: 10 } })

    const countryFilter = wrapper.findAll('.ct-pame-filter')[1]
    await countryFilter.find('.ct-pame-filter__button').trigger('click')
    await countryFilter.find('.ct-pame-filter-option__checkbox').setValue(true)
    await countryFilter.find('.ct-pame-filter-mobile__button-apply').trigger('click')

    expect(wrapper.emitted('apply')?.[0]).toEqual(['country', ['Kenya']])
  })

  it('shows a filter as selected once it has applied options, looked up by name', () => {
    const wrapper = mount(PameFilters, {
      props: {
        filters,
        isFetching: false,
        selectedFilterOptions: [
          { name: 'method', options: [], type: 'multiple' },
          { name: 'country', options: ['Kenya'], type: 'multiple' }
        ],
        totalItems: 10
      }
    })

    const countryButton = wrapper.findAll('.ct-pame-filter__button')[1]
    expect(countryButton.classes()).toContain('ct-pame-filter__button--has-selected')
    expect(countryButton.text()).toContain('1')
  })

  it('bubbles update:isFetching from the download button up to the parent', () => {
    const wrapper = mount(PameFilters, { props: { filters, isFetching: false, selectedFilterOptions, totalItems: 10 } })

    wrapper.findComponent(PameTableDownloadCsv).vm.$emit('update:isFetching', true)

    expect(wrapper.emitted('update:isFetching')?.[0]).toEqual([true])
  })
})
