import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Tooltip from '@/components/Tooltip/Index.vue'

describe('Tooltip', () => {
  it('renders the trigger slot and the text via v-html', () => {
    const wrapper = mount(Tooltip, {
      props: { text: 'Helpful <b>info</b>' },
      slots: { default: 'Trigger' }
    })

    expect(wrapper.find('.ct-tooltip__trigger').text()).toBe('Trigger')
    expect(wrapper.find('.ct-tooltip__target').html()).toContain('Helpful <b>info</b>')
  })

  it('toggles on mouseenter/mouseleave when onHover is true (default)', async () => {
    const wrapper = mount(Tooltip, { props: { text: 'Info' } })

    expect(wrapper.classes()).not.toContain('ct-tooltip--active')

    await wrapper.find('.ct-tooltip__trigger').trigger('mouseenter')
    expect(wrapper.classes()).toContain('ct-tooltip--active')

    await wrapper.find('.ct-tooltip__trigger').trigger('mouseleave')
    expect(wrapper.classes()).not.toContain('ct-tooltip--active')
  })

  it('toggles on click and closes via the close button when onHover is false', async () => {
    const wrapper = mount(Tooltip, { props: { text: 'Info', onHover: false } })

    expect(wrapper.find('.ct-tooltip__target').attributes('style')).toContain('display: none')

    await wrapper.find('.ct-tooltip__trigger').trigger('click')
    expect(wrapper.classes()).toContain('ct-tooltip--active')
    expect(wrapper.find('.ct-tooltip__target').attributes('style')).not.toContain('display: none')

    await wrapper.find('.ct-tooltip__close').trigger('click')
    expect(wrapper.classes()).not.toContain('ct-tooltip--active')
    expect(wrapper.find('.ct-tooltip__target').attributes('style')).toContain('display: none')
  })

  it('closes when clicking outside the tooltip', async () => {
    const wrapper = mount(Tooltip, {
      props: { text: 'Info', onHover: false },
      attachTo: document.body
    })

    await wrapper.find('.ct-tooltip__trigger').trigger('click')
    expect(wrapper.classes()).toContain('ct-tooltip--active')

    // vueuse's onClickOutside briefly guards against double-firing for the same
    // click sequence (touch+click), so a synchronous second click right after the
    // first is ignored — let a macrotask pass first, same as a real user would.
    await new Promise(resolve => setTimeout(resolve, 0))

    document.body.click()
    await wrapper.vm.$nextTick()
    expect(wrapper.classes()).not.toContain('ct-tooltip--active')

    wrapper.unmount()
  })

  it('closes on Escape keypress', async () => {
    const wrapper = mount(Tooltip, {
      props: { text: 'Info', onHover: false },
      attachTo: document.body
    })

    await wrapper.find('.ct-tooltip__trigger').trigger('click')
    expect(wrapper.classes()).toContain('ct-tooltip--active')

    await wrapper.find('.ct-tooltip').trigger('keydown', { key: 'Escape' })
    expect(wrapper.classes()).not.toContain('ct-tooltip--active')

    wrapper.unmount()
  })
})
