import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import TooltipSecond from '@/components/Tooltip/Second.vue'

describe('TooltipSecond', () => {
  it('renders the trigger, header and content slots', async () => {
    const wrapper = mount(TooltipSecond, {
      slots: {
        trigger: 'Trigger',
        header: '<span>Header</span>',
        content: '<p>Content</p>'
      }
    })

    expect(wrapper.find('.ct-tooltip-second__trigger').text()).toBe('Trigger')

    // The target (header/content) is only mounted (v-if) once active.
    await wrapper.find('.ct-tooltip-second__trigger').trigger('mouseenter')

    expect(wrapper.find('.ct-tooltip-second__header').html()).toContain('Header')
    expect(wrapper.find('.ct-tooltip-second__target').html()).toContain('Content')
  })

  it('toggles on mouseenter/mouseleave when onHover is true (default)', async () => {
    const wrapper = mount(TooltipSecond)

    expect(wrapper.classes()).not.toContain('ct-tooltip-second--active')

    await wrapper.find('.ct-tooltip-second__trigger').trigger('mouseenter')
    expect(wrapper.classes()).toContain('ct-tooltip-second--active')

    await wrapper.find('.ct-tooltip-second__trigger').trigger('mouseleave')
    expect(wrapper.classes()).not.toContain('ct-tooltip-second--active')
  })

  it('toggles on click and closes via the close button when onHover is false', async () => {
    const wrapper = mount(TooltipSecond, { props: { onHover: false } })

    // The target is v-if'd (not merely hidden via style) until active.
    expect(wrapper.find('.ct-tooltip-second__target').exists()).toBe(false)

    await wrapper.find('.ct-tooltip-second__trigger').trigger('click')
    expect(wrapper.classes()).toContain('ct-tooltip-second--active')
    expect(wrapper.find('.ct-tooltip-second__target').exists()).toBe(true)

    await wrapper.find('.ct-tooltip-second__close').trigger('click')
    expect(wrapper.classes()).not.toContain('ct-tooltip-second--active')
    expect(wrapper.find('.ct-tooltip-second__target').exists()).toBe(false)
  })

  it('closes when clicking outside the tooltip', async () => {
    const wrapper = mount(TooltipSecond, {
      props: { onHover: false },
      attachTo: document.body
    })

    await wrapper.find('.ct-tooltip-second__trigger').trigger('click')
    expect(wrapper.classes()).toContain('ct-tooltip-second--active')

    // onClickOutside ignores a second click in the same tick (its touch+click
    // guard), so let a macrotask pass, as a real user would.
    await new Promise(resolve => setTimeout(resolve, 0))

    document.body.click()
    await wrapper.vm.$nextTick()
    expect(wrapper.classes()).not.toContain('ct-tooltip-second--active')

    wrapper.unmount()
  })

  it('closes on Escape keypress', async () => {
    const wrapper = mount(TooltipSecond, {
      props: { onHover: false },
      attachTo: document.body
    })

    await wrapper.find('.ct-tooltip-second__trigger').trigger('click')
    expect(wrapper.classes()).toContain('ct-tooltip-second--active')

    await wrapper.find('.ct-tooltip-second').trigger('keydown', { key: 'Escape' })
    expect(wrapper.classes()).not.toContain('ct-tooltip-second--active')

    wrapper.unmount()
  })
})
