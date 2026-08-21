import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import TabStrip from '@/components/TabStrip/Index.vue'

const children = [
  { id: 'region', title: 'Region' },
  { id: 'country', title: 'Country' },
  { id: 'site', title: 'Site' }
]

function mountTabStrip(props: Record<string, unknown> = {}) {
  return mount(TabStrip, { props: { children, ...props } })
}

describe('TabStrip', () => {
  beforeEach(() => {
    window.gtag = vi.fn()
  })

  it('selects the first child by default', () => {
    const wrapper = mountTabStrip()

    expect(wrapper.findAll('li')[0].classes()).toContain('ct-tab-strip-tab--active')
  })

  it('honours defaultSelectedId over the first child', () => {
    const wrapper = mountTabStrip({ defaultSelectedId: 'site' })

    expect(wrapper.findAll('li')[2].classes()).toContain('ct-tab-strip-tab--active')
  })

  it('ignores a click on the already-active tab', async () => {
    const wrapper = mountTabStrip({ defaultSelectedId: 'country' })

    await wrapper.findAll('li')[1].trigger('click')

    expect(wrapper.emitted('click:tab')).toBeUndefined()
    expect(window.gtag).not.toHaveBeenCalled()
  })

  it('does not re-emit when the parent mirrors the emitted id back into preSelectedId', async () => {
    const wrapper = mountTabStrip()

    await wrapper.findAll('li')[1].trigger('click')
    await wrapper.setProps({ preSelectedId: 'country' })

    expect(wrapper.emitted('click:tab')).toHaveLength(1)
  })

  it('emits click:tab and updates the active tab on click', async () => {
    const wrapper = mountTabStrip()

    await wrapper.findAll('li')[1].trigger('click')

    expect(wrapper.emitted('click:tab')?.[0]).toEqual(['country'])
    expect(wrapper.findAll('li')[1].classes()).toContain('ct-tab-strip-tab--active')
  })

  it('follows preSelectedId when it changes externally', async () => {
    const wrapper = mountTabStrip({ preSelectedId: 'region' })

    await wrapper.setProps({ preSelectedId: 'site' })

    expect(wrapper.findAll('li')[2].classes()).toContain('ct-tab-strip-tab--active')
    expect(wrapper.emitted('click:tab')?.at(-1)).toEqual(['site'])
  })

  it('fires a GA4 event with the tab title when gaId is set', async () => {
    const wrapper = mountTabStrip({ gaId: 'Component: search areas' })

    await wrapper.findAll('li')[1].trigger('click')

    expect(window.gtag).toHaveBeenCalledWith('event', 'click', {
      event_label: 'Component: search areas - Tab: Country'
    })
  })

  it('marks tabs aria-disabled and ignores clicks when disabled', async () => {
    const wrapper = mountTabStrip({ disabled: true })

    expect(wrapper.findAll('li')[1].attributes('aria-disabled')).toBe('true')

    await wrapper.findAll('li')[1].trigger('click')

    expect(wrapper.emitted('click:tab')).toBeUndefined()
    expect(wrapper.findAll('li')[0].classes()).toContain('ct-tab-strip-tab--active')
  })
})
