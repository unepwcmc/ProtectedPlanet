import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import TooltipPanel from '@/components/Tooltip/Panel.vue'

describe('Tooltip Panel', () => {
  it('renders the trigger, header and content slots', async () => {
    const wrapper = mount(TooltipPanel, {
      slots: {
        trigger: 'Trigger',
        header: '<span>Header</span>',
        content: '<p>Content</p>'
      }
    })

    expect(wrapper.find('.ct-tooltip-panel__trigger').text()).toBe('Trigger')

    // The target (header/content) is only mounted (v-if) once active.
    await wrapper.find('.ct-tooltip-panel__trigger').trigger('mouseenter')

    expect(wrapper.find('.ct-tooltip-panel__header').html()).toContain('Header')
    expect(wrapper.find('.ct-tooltip-panel__target').html()).toContain('Content')
  })

  it('toggles on mouseenter/mouseleave when onHover is true (default)', async () => {
    const wrapper = mount(TooltipPanel)

    expect(wrapper.classes()).not.toContain('ct-tooltip-panel--active')

    await wrapper.find('.ct-tooltip-panel__trigger').trigger('mouseenter')
    expect(wrapper.classes()).toContain('ct-tooltip-panel--active')

    await wrapper.find('.ct-tooltip-panel__trigger').trigger('mouseleave')
    expect(wrapper.classes()).not.toContain('ct-tooltip-panel--active')
  })

  it('toggles on click and closes via the close button when onHover is false', async () => {
    const wrapper = mount(TooltipPanel, { props: { onHover: false } })

    // The target is v-if'd (not merely hidden via style) until active.
    expect(wrapper.find('.ct-tooltip-panel__target').exists()).toBe(false)

    await wrapper.find('.ct-tooltip-panel__trigger').trigger('click')
    expect(wrapper.classes()).toContain('ct-tooltip-panel--active')
    expect(wrapper.find('.ct-tooltip-panel__target').exists()).toBe(true)

    await wrapper.find('.ct-tooltip-panel__close').trigger('click')
    expect(wrapper.classes()).not.toContain('ct-tooltip-panel--active')
    expect(wrapper.find('.ct-tooltip-panel__target').exists()).toBe(false)
  })

  it('closes when clicking outside the tooltip', async () => {
    const wrapper = mount(TooltipPanel, {
      props: { onHover: false },
      attachTo: document.body
    })

    await wrapper.find('.ct-tooltip-panel__trigger').trigger('click')
    expect(wrapper.classes()).toContain('ct-tooltip-panel--active')

    // onClickOutside ignores a second click in the same tick (its touch+click
    // guard), so let a macrotask pass, as a real user would.
    await new Promise(resolve => setTimeout(resolve, 0))

    document.body.click()
    await wrapper.vm.$nextTick()
    expect(wrapper.classes()).not.toContain('ct-tooltip-panel--active')

    wrapper.unmount()
  })

  it('closes on Escape keypress', async () => {
    const wrapper = mount(TooltipPanel, {
      props: { onHover: false },
      attachTo: document.body
    })

    await wrapper.find('.ct-tooltip-panel__trigger').trigger('click')
    expect(wrapper.classes()).toContain('ct-tooltip-panel--active')

    await wrapper.find('.ct-tooltip-panel').trigger('keydown', { key: 'Escape' })
    expect(wrapper.classes()).not.toContain('ct-tooltip-panel--active')

    wrapper.unmount()
  })
})
