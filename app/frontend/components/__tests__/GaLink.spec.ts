import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import GaLink from '@/components/GaLink.vue'

describe('GaLink', () => {
  beforeEach(() => {
    window.gtag = vi.fn()
  })

  it('renders the href and HTML label', () => {
    const wrapper = mount(GaLink, {
      props: { href: '/download', text: 'Download <b>now</b>' }
    })

    expect(wrapper.attributes('href')).toBe('/download')
    expect(wrapper.html()).toContain('Download <b>now</b>')
  })

  it('fires a GA4 event with the gaId-derived label on click', async () => {
    const wrapper = mount(GaLink, {
      props: { href: '/download', text: 'Download', gaId: 'Download global statistics' }
    })

    await wrapper.trigger('click')

    expect(window.gtag).toHaveBeenCalledWith('event', 'click', {
      event_label: 'Link - Download global statistics'
    })
  })

  it('does not fire an event when gaId is absent', async () => {
    const wrapper = mount(GaLink, { props: { href: '/download', text: 'Download' } })

    await wrapper.trigger('click')

    expect(window.gtag).not.toHaveBeenCalled()
  })
})
