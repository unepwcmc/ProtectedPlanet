import { describe, it, expect, afterEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import FiltersPanel from '@/components/Filters/Panel/Index.vue'

const filters = [
  {
    id: 'topics',
    title: 'Topics',
    type: 'checkbox' as const,
    options: [{ id: 'wdpa', title: 'WDPA' }]
  }
]

// useBreakpoint is mocked rather than driven by window.innerWidth + a `resize`
// event: a real resize also reaches the wrappers other tests here deliberately
// leave mounted, flipping their branch and re-firing Mobile's scroll-lock
// watcher. A mocked composable only affects wrappers mounted after it is set.
const breakpoint = { isSmall: false, isMedium: true }

vi.mock('@/composables/useBreakpoint', () => ({
  default: () => ({ isSmall: breakpoint.isSmall, isMedium: breakpoint.isMedium })
}))

function setBreakpoint(next: { isSmall: boolean, isMedium: boolean }) {
  breakpoint.isSmall = next.isSmall
  breakpoint.isMedium = next.isMedium
}

describe('FiltersPanel', () => {
  // jsdom's `document` is shared, and several tests below mount with
  // isActive: true without unmounting — otherwise a locked body scroll leaks.
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
        keepMounted: true,
        preSelected: { topics: ['wdpa'] },
        textClear: 'Clear',
        title: 'Filters'
      }
    })

    expect(wrapper.attributes('style')).toContain('display: none')
    expect(wrapper.emitted('update:filterGroup')?.[0]).toEqual([{ id: 'topics', options: ['wdpa'] }])
  })

  it('is not rendered at all when inactive without keepMounted', () => {
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

    expect(wrapper.find('.ct-filters-panel').exists()).toBe(false)
    expect(wrapper.emitted('update:filterGroup')).toBeUndefined()
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

    await wrapper.find('.ct-filters-panel-mobile__footer').trigger('click')

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

    expect(mobile.find('.ct-filters-panel-mobile').exists()).toBe(true)
    expect(mobile.find('.ct-filters-panel-desktop').exists()).toBe(false)
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

    expect(desktop.find('.ct-filters-panel-desktop').exists()).toBe(true)
    expect(desktop.find('.ct-filters-panel-mobile').exists()).toBe(false)
    desktop.unmount()
  })

  it('locks background scroll while active, restores it once inactive', async () => {
    const wrapper = mount(FiltersPanel, {
      props: {
        filterCloseText: 'View results',
        filters,
        filtersTitle: 'Filter by',
        isActive: false,
        keepMounted: true,
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

  // The mobile sheet covers the viewport, so it owes the keyboard the same exit
  // the visible close control gives the mouse.
  it('announces the mobile sheet as a modal dialog and closes it on Escape', async () => {
    setBreakpoint({ isSmall: true, isMedium: false })

    const wrapper = mount(FiltersPanel, {
      props: {
        filterCloseText: 'View results',
        filters,
        filtersTitle: 'Filter by',
        isActive: false,
        textClear: 'Clear',
        title: 'Filters'
      },
      attachTo: document.body
    })

    await wrapper.setProps({ isActive: true })

    const dialog = wrapper.find('.ct-filters-panel-mobile')
    expect(dialog.attributes('role')).toBe('dialog')
    expect(dialog.attributes('aria-modal')).toBe('true')
    expect(dialog.attributes('aria-label')).toBe('Filters')

    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', cancelable: true }))
    expect(wrapper.emitted('toggle:filterPane')).toHaveLength(1)

    wrapper.unmount()
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
