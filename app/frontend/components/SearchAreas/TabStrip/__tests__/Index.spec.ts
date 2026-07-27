import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchAreasTabStrip from '@/components/SearchAreas/TabStrip/Index.vue'

const children = [
  { id: 'region', title: 'Region' },
  { id: 'country', title: 'Country' },
  { id: 'site', title: 'Site' }
]

describe('SearchAreasTabStrip', () => {
  beforeEach(() => {
    window.gtag = vi.fn()
  })

  it('selects the first child by default', () => {
    const wrapper = mount(SearchAreasTabStrip, { props: { children } })

    expect(wrapper.findAll('li')[0].classes()).toContain('active')
  })

  it('honours defaultSelectedId over the first child', () => {
    const wrapper = mount(SearchAreasTabStrip, { props: { children, defaultSelectedId: 'site' } })

    expect(wrapper.findAll('li')[2].classes()).toContain('active')
  })

  it('emits click:tab and updates the active tab on click', async () => {
    const wrapper = mount(SearchAreasTabStrip, { props: { children } })

    await wrapper.findAll('li')[1].trigger('click')

    expect(wrapper.emitted('click:tab')?.[0]).toEqual(['country'])
    expect(wrapper.findAll('li')[1].classes()).toContain('active')
  })

  it('follows preSelectedId when it changes externally', async () => {
    const wrapper = mount(SearchAreasTabStrip, { props: { children, preSelectedId: 'region' } })

    await wrapper.setProps({ preSelectedId: 'site' })

    expect(wrapper.findAll('li')[2].classes()).toContain('active')
    expect(wrapper.emitted('click:tab')?.at(-1)).toEqual(['site'])
  })

  it('fires a GA4 event with the tab title when gaId is set', async () => {
    const wrapper = mount(SearchAreasTabStrip, { props: { children, gaId: 'Component: search areas' } })

    await wrapper.findAll('li')[1].trigger('click')

    expect(window.gtag).toHaveBeenCalledWith('event', 'click', {
      event_label: 'Component: search areas - Tab: Country'
    })
  })
})
