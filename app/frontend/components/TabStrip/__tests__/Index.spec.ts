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

    expect(wrapper.findAll('[role="tab"]')[0].classes()).toContain('ct-tab-strip-tab--active')
  })

  // Each tab is a real <button>, so Enter and Space activate it through the
  // platform's own click synthesis -- there are no key handlers left to test, and
  // jsdom does not synthesise that click, so the element type IS the contract.
  it('renders each tab as a natively activatable button', () => {
    const wrapper = mountTabStrip()
    const tabs = wrapper.findAll('[role="tab"]')

    expect(tabs).toHaveLength(3)
    tabs.forEach(tab => expect(tab.element.tagName).toBe('BUTTON'))
  })

  // A disabled tab must be skipped by the tab sequence, not focusable-but-inert.
  it('drops a disabled tab out of the tab sequence and ignores its clicks', async () => {
    const wrapper = mountTabStrip({ disabled: true })
    const tabs = wrapper.findAll('[role="tab"]')

    expect(tabs[1].attributes('tabindex')).toBe('-1')

    await tabs[1].trigger('click')
    expect(tabs[1].classes()).not.toContain('ct-tab-strip-tab--active')
  })

  it('honours defaultSelectedId over the first child', () => {
    const wrapper = mountTabStrip({ defaultSelectedId: 'site' })

    expect(wrapper.findAll('[role="tab"]')[2].classes()).toContain('ct-tab-strip-tab--active')
  })

  it('ignores a click on the already-active tab', async () => {
    const wrapper = mountTabStrip({ defaultSelectedId: 'country' })

    await wrapper.findAll('[role="tab"]')[1].trigger('click')

    expect(wrapper.emitted('click:tab')).toBeUndefined()
    expect(window.gtag).not.toHaveBeenCalled()
  })

  it('does not re-emit when the parent mirrors the emitted id back into preSelectedId', async () => {
    const wrapper = mountTabStrip()

    await wrapper.findAll('[role="tab"]')[1].trigger('click')
    await wrapper.setProps({ preSelectedId: 'country' })

    expect(wrapper.emitted('click:tab')).toHaveLength(1)
  })

  it('emits click:tab and updates the active tab on click', async () => {
    const wrapper = mountTabStrip()

    await wrapper.findAll('[role="tab"]')[1].trigger('click')

    expect(wrapper.emitted('click:tab')?.[0]).toEqual(['country'])
    expect(wrapper.findAll('[role="tab"]')[1].classes()).toContain('ct-tab-strip-tab--active')
  })

  it('follows preSelectedId when it changes externally', async () => {
    const wrapper = mountTabStrip({ preSelectedId: 'region' })

    await wrapper.setProps({ preSelectedId: 'site' })

    expect(wrapper.findAll('[role="tab"]')[2].classes()).toContain('ct-tab-strip-tab--active')
    expect(wrapper.emitted('click:tab')?.at(-1)).toEqual(['site'])
  })

  it('fires a GA4 event with the tab title when gaId is set', async () => {
    const wrapper = mountTabStrip({ gaId: 'Component: search areas' })

    await wrapper.findAll('[role="tab"]')[1].trigger('click')

    expect(window.gtag).toHaveBeenCalledWith('event', 'click', {
      event_label: 'Component: search areas - Tab: Country'
    })
  })

  it('marks tabs aria-disabled and ignores clicks when disabled', async () => {
    const wrapper = mountTabStrip({ disabled: true })

    expect(wrapper.findAll('[role="tab"]')[1].attributes('aria-disabled')).toBe('true')

    await wrapper.findAll('[role="tab"]')[1].trigger('click')

    expect(wrapper.emitted('click:tab')).toBeUndefined()
    expect(wrapper.findAll('[role="tab"]')[0].classes()).toContain('ct-tab-strip-tab--active')
  })
})
