import { describe, it, expect, afterEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import FiltersPanel from '@/components/Listing/FiltersPanel/Index.vue'

const filters = [
  {
    id: 'topics',
    title: 'Topics',
    type: 'checkbox' as const,
    options: [{ id: 'wdpa', title: 'WDPA' }]
  }
]

// FiltersPanel/Index.vue picks Mobile vs Desktop via useBreakpoint(), which
// reads real window dimensions through vueuse's useWindowSize. Driving that
// with actual window.innerWidth + a dispatched `resize` event would also
// reach every other still-mounted wrapper in this file (several tests below
// intentionally don't unmount), flipping their v-if/v-else branch and
// re-triggering Mobile's scroll-lock watcher outside of their own test. A
// mocked composable only affects wrappers mounted after it's set, so it
// can't leak.
const breakpoint = { isSmall: false, isMedium: true }

vi.mock('@/composables/useBreakpoint', () => ({
  default: () => ({ isSmall: breakpoint.isSmall, isMedium: breakpoint.isMedium })
}))

function setBreakpoint(next: { isSmall: boolean, isMedium: boolean }) {
  breakpoint.isSmall = next.isSmall
  breakpoint.isMedium = next.isMedium
}

describe('Listing FiltersPanel', () => {
  // Several tests below mount with isActive: true and don't unmount — since
  // jsdom's `document` is shared across tests in this file, that would leak
  // a locked body scroll into later tests' initial-state assertions.
  afterEach(() => {
    document.body.style.overflow = ''
    setBreakpoint({ isSmall: false, isMedium: true })
  })

  it('is hidden when not active, but stays mounted so preSelected filters still prime the parent', () => {
    const wrapper = mount(FiltersPanel, {
      props: {
        filterCloseText: 'View results',
        filters,
        filtersTitle: 'Filter by',
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
        filters,
        filtersTitle: 'Filter by',
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
        filters,
        filtersTitle: 'Filter by',
        isActive: true,
        textClear: 'Clear',
        title: 'Filters'
      }
    })

    await wrapper.find('.ct-listing-filters-panel-mobile__footer').trigger('click')

    expect(wrapper.emitted('toggle:filterPane')).toHaveLength(1)
  })

  it('renders only the mobile panel on small/medium screens, and only the desktop panel above that', () => {
    setBreakpoint({ isSmall: true, isMedium: false })
    const mobile = mount(FiltersPanel, {
      props: {
        filterCloseText: 'View results',
        filters,
        filtersTitle: 'Filter by',
        isActive: true,
        textClear: 'Clear',
        title: 'Filters'
      }
    })

    expect(mobile.find('.ct-listing-filters-panel-mobile').exists()).toBe(true)
    expect(mobile.find('.ct-listing-filters-panel-desktop').exists()).toBe(false)
    mobile.unmount()

    setBreakpoint({ isSmall: false, isMedium: false })
    const desktop = mount(FiltersPanel, {
      props: {
        filterCloseText: 'View results',
        filters,
        filtersTitle: 'Filter by',
        isActive: true,
        textClear: 'Clear',
        title: 'Filters'
      }
    })

    expect(desktop.find('.ct-listing-filters-panel-desktop').exists()).toBe(true)
    expect(desktop.find('.ct-listing-filters-panel-mobile').exists()).toBe(false)
    desktop.unmount()
  })

  it('locks background scroll while active, restores it once inactive', async () => {
    const wrapper = mount(FiltersPanel, {
      props: {
        filterCloseText: 'View results',
        filters,
        filtersTitle: 'Filter by',
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
        filters,
        filtersTitle: 'Filter by',
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
