import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import NavBarDropdownDesktop from '@/components/NavBar/Dropdown/Desktop.vue'

const link = {
  id: 'data',
  label: 'Data',
  url: '/en/data',
  is_current_page: false,
  children: [
    { id: 'wdpa', label: 'WDPA', url: '/en/data/wdpa', is_current_page: false },
    { id: 'wdoecm', label: 'WD-OECM', url: '/en/data/wdoecm', is_current_page: false }
  ]
}

describe('NavBarDropdownDesktop', () => {
  it('renders the trigger label and child links', () => {
    const wrapper = mount(NavBarDropdownDesktop, { props: { link } })

    expect(wrapper.find('.ct-nav-bar-dropdown-desktop__label').text()).toBe('Data')
    const children = wrapper.findAll('.ct-nav-bar-dropdown-desktop__link')
    expect(children).toHaveLength(2)
    expect(children[0].text()).toBe('WDPA')
  })

  it('opens on mouseenter and closes on mouseleave', async () => {
    const wrapper = mount(NavBarDropdownDesktop, { props: { link } })

    expect(wrapper.classes()).not.toContain('ct-nav-bar-dropdown-desktop--active')

    await wrapper.trigger('mouseenter')
    expect(wrapper.classes()).toContain('ct-nav-bar-dropdown-desktop--active')

    await wrapper.trigger('mouseleave')
    expect(wrapper.classes()).not.toContain('ct-nav-bar-dropdown-desktop--active')
  })

  it('leaves the section link alone, so it navigates normally', async () => {
    const wrapper = mount(NavBarDropdownDesktop, { props: { link } })

    await wrapper.find('.ct-nav-bar-dropdown-desktop__label').trigger('click')
    expect(wrapper.classes()).not.toContain('ct-nav-bar-dropdown-desktop--active')
  })

  // The only way in without a mouse: hover cannot be performed from a keyboard,
  // and the section link navigates away rather than opening the submenu.
  it('opens and closes the submenu from the toggle button', async () => {
    const wrapper = mount(NavBarDropdownDesktop, { props: { link } })
    const toggle = wrapper.find('.ct-nav-bar-dropdown-desktop__toggle-button')

    expect(toggle.attributes('aria-expanded')).toBe('false')

    await toggle.trigger('click')
    expect(wrapper.classes()).toContain('ct-nav-bar-dropdown-desktop--active')
    expect(toggle.attributes('aria-expanded')).toBe('true')

    await toggle.trigger('click')
    expect(wrapper.classes()).not.toContain('ct-nav-bar-dropdown-desktop--active')
  })

  it('opens when focus enters and closes when it leaves for somewhere outside', async () => {
    const wrapper = mount(NavBarDropdownDesktop, { props: { link }, attachTo: document.body })

    await wrapper.trigger('focusin')
    expect(wrapper.classes()).toContain('ct-nav-bar-dropdown-desktop--active')

    // Focus moving to a child link must not close it.
    const childLink = wrapper.find('.ct-nav-bar-dropdown-desktop__link').element
    await wrapper.trigger('focusout', { relatedTarget: childLink })
    expect(wrapper.classes()).toContain('ct-nav-bar-dropdown-desktop--active')

    await wrapper.trigger('focusout', { relatedTarget: document.body })
    expect(wrapper.classes()).not.toContain('ct-nav-bar-dropdown-desktop--active')

    wrapper.unmount()
  })

  it('closes when clicking outside the dropdown', async () => {
    const wrapper = mount(NavBarDropdownDesktop, { props: { link }, attachTo: document.body })

    await wrapper.trigger('mouseenter')
    expect(wrapper.classes()).toContain('ct-nav-bar-dropdown-desktop--active')

    document.body.click()
    await wrapper.vm.$nextTick()
    expect(wrapper.classes()).not.toContain('ct-nav-bar-dropdown-desktop--active')

    wrapper.unmount()
  })

  it('closes on Escape keypress', async () => {
    const wrapper = mount(NavBarDropdownDesktop, { props: { link }, attachTo: document.body })

    await wrapper.trigger('mouseenter')
    expect(wrapper.classes()).toContain('ct-nav-bar-dropdown-desktop--active')

    await wrapper.trigger('keydown', { key: 'Escape' })
    expect(wrapper.classes()).not.toContain('ct-nav-bar-dropdown-desktop--active')

    wrapper.unmount()
  })
})
