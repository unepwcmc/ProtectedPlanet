import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import Toggler from '@/components/Map/Toggler.vue'

describe('Map Toggler', () => {
  beforeEach(() => {
    window.gtag = vi.fn()
  })

  it('shows the on/off text based on active state', () => {
    const wrapper = mount(Toggler, { props: { active: true } })
    expect(wrapper.text()).toBe('ON')
  })

  it('emits change with the inverted state on click and does not fire GA without a gaId', async () => {
    const wrapper = mount(Toggler, { props: { active: false } })

    await wrapper.trigger('click')

    expect(wrapper.emitted('change')?.[0]).toEqual([true])
    expect(window.gtag).not.toHaveBeenCalled()
  })

  it('fires a GA4 event when gaId is given', async () => {
    const wrapper = mount(Toggler, { props: { active: false, gaId: 'terrestrial' } })

    await wrapper.trigger('click')

    expect(window.gtag).toHaveBeenCalledWith('event', 'click', {
      event_label: 'terrestrial - Toggle map layer: true'
    })
  })
})
