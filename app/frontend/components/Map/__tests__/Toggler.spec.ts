import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Toggler from '@/components/Map/Toggler.vue'

describe('Map Toggler', () => {
  it('shows the on/off text based on active state', () => {
    const wrapper = mount(Toggler, { props: { active: true } })
    expect(wrapper.text()).toBe('ON')
  })

  it('is a switch that reports its state, and emits the inverted state on click', async () => {
    const wrapper = mount(Toggler, { props: { active: false, label: 'Terrestrial' } })

    expect(wrapper.element.tagName).toBe('BUTTON')
    expect(wrapper.attributes('role')).toBe('switch')
    expect(wrapper.attributes('aria-checked')).toBe('false')
    expect(wrapper.attributes('aria-label')).toBe('Terrestrial')

    await wrapper.trigger('click')

    expect(wrapper.emitted('change')?.[0]).toEqual([true])
  })

  // Map/Overlay.vue makes the whole legend row one switch and draws the pill
  // inside it, so a second control there would announce the same state twice.
  it('renders no control at all in presentational mode', () => {
    const wrapper = mount(Toggler, { props: { active: true, presentational: true } })

    expect(wrapper.element.tagName).toBe('SPAN')
    expect(wrapper.attributes('aria-hidden')).toBe('true')
    expect(wrapper.attributes('role')).toBeUndefined()
  })
})
