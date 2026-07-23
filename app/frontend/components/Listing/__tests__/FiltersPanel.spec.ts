import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import FiltersPanel from '@/components/Listing/FiltersPanel.vue'

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
  it('is hidden when not active', () => {
    const wrapper = mount(FiltersPanel, {
      props: {
        filterCloseText: 'View results',
        filterGroups,
        isActive: false,
        textClear: 'Clear',
        title: 'Filters'
      }
    })

    expect(wrapper.attributes('style')).toContain('display: none')
  })

  it('accumulates filter changes into a single update:filterGroup payload', async () => {
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

    expect(wrapper.emitted('update:filterGroup')?.at(-1)).toEqual([{ topics: ['wdpa'] }])
  })

  it('emits toggle:filterPane when the close view is clicked', async () => {
    const wrapper = mount(FiltersPanel, {
      props: {
        filterCloseText: 'View results',
        filterGroups,
        isActive: true,
        textClear: 'Clear',
        title: 'Filters'
      }
    })

    await wrapper.find('.filter__pane-view').trigger('click')

    expect(wrapper.emitted('toggle:filterPane')).toHaveLength(1)
  })
})
