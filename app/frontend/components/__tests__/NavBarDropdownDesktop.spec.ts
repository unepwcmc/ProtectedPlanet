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

  it('ignores click on the toggle, so the link navigates normally', async () => {
    const wrapper = mount(NavBarDropdownDesktop, { props: { link } })

    await wrapper.find('.ct-nav-bar-dropdown-desktop__toggle').trigger('click')
    expect(wrapper.classes()).not.toContain('ct-nav-bar-dropdown-desktop--active')
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
