import { describe, it, expect, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import FiltersPanel from '@/components/Listing/FiltersPanel/Index.vue'

const filterGroups = [
  {
    title: 'Filter by',
    filters: [
      {
        id: 'topics',
        title: 'Topics',
        type: 'checkbox' as const,
        options: [{ id: 'wdpa', title: 'WDPA' }]
      }
    ]
  }
]

describe('Listing FiltersPanel', () => {
  // Several tests below mount with isActive: true and don't unmount — since
  // jsdom's `document` is shared across tests in this file, that would leak
  // a locked body scroll into later tests' initial-state assertions.
  afterEach(() => {
    document.body.style.overflow = ''
  })

  it('is hidden when not active, but stays mounted so preSelected filters still prime the parent', () => {
    const wrapper = mount(FiltersPanel, {
      props: {
        filterCloseText: 'View results',
        filterGroups,
        isActive: false,
        preSelected: { topics: ['wdpa'] },
        textClear: 'Clear',
        title: 'Filters'
      }
    })

    expect(wrapper.attributes('style')).toContain('display: none')
    expect(wrapper.emitted('update:filterGroup')?.[0]).toEqual([{ id: 'topics', options: ['wdpa'] }])
  })

  it('emits update:filterGroup with the id and selected options for the changed group', async () => {
    const wrapper = mount(FiltersPanel, {
      props: {
        filterCloseText: 'View results',
        filterGroups,
        isActive: true,
        textClear: 'Clear',
        title: 'Filters'
      }
    })

    await wrapper.find('input[value="wdpa"]').setValue(true)

    expect(wrapper.emitted('update:filterGroup')?.at(-1)).toEqual([{ id: 'topics', options: ['wdpa'] }])
  })

  it('emits toggle:filterPane when the close view is clicked (mobile panel)', async () => {
    const wrapper = mount(FiltersPanel, {
      props: {
        filterCloseText: 'View results',
        filterGroups,
        isActive: true,
        textClear: 'Clear',
        title: 'Filters'
      }
    })

    await wrapper.find('.ct-listing-filters-panel-mobile__footer').trigger('click')

    expect(wrapper.emitted('toggle:filterPane')).toHaveLength(1)
  })

  it('renders both the desktop and mobile panels, letting CSS breakpoints pick which is visible', () => {
    const wrapper = mount(FiltersPanel, {
      props: {
        filterCloseText: 'View results',
        filterGroups,
        isActive: true,
        textClear: 'Clear',
        title: 'Filters'
      }
    })

    expect(wrapper.find('.ct-listing-filters-panel-desktop__groups').exists()).toBe(true)
    expect(wrapper.find('.ct-listing-filters-panel-mobile').exists()).toBe(true)
  })

  it('locks background scroll while active, restores it once inactive', async () => {
    const wrapper = mount(FiltersPanel, {
      props: {
        filterCloseText: 'View results',
        filterGroups,
        isActive: false,
        textClear: 'Clear',
        title: 'Filters'
      }
    })

    expect(document.body.style.overflow).toBe('')

    await wrapper.setProps({ isActive: true })
    expect(document.body.style.overflow).toBe('hidden')

    await wrapper.setProps({ isActive: false })
    expect(document.body.style.overflow).toBe('')
  })

  it('restores background scroll on unmount', async () => {
    const wrapper = mount(FiltersPanel, {
      props: {
        filterCloseText: 'View results',
        filterGroups,
        isActive: true,
        textClear: 'Clear',
        title: 'Filters'
      }
    })

    await wrapper.vm.$nextTick()
    expect(document.body.style.overflow).toBe('hidden')

    wrapper.unmount()
    expect(document.body.style.overflow).toBe('')
  })
})
