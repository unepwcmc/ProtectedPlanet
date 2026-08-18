import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import NavBarDropdownMobile from '@/components/NavBar/Dropdown/Mobile.vue'

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

describe('NavBarDropdownMobile', () => {
  it('renders the trigger label and child links', () => {
    const wrapper = mount(NavBarDropdownMobile, { props: { link } })

    expect(wrapper.find('.nav-bar-dropdown-toggle').text()).toBe('Data')
    const children = wrapper.findAll('.ct-nav-bar-dropdown-mobile__link')
    expect(children).toHaveLength(2)
    expect(children[0].text()).toBe('WDPA')
  })

  it('toggles the accordion open and closed on click, since mobile has no hover', async () => {
    const wrapper = mount(NavBarDropdownMobile, { props: { link } })

    expect(wrapper.find('.ct-nav-bar-dropdown-mobile__wrapper').classes())
      .not.toContain('ct-nav-bar-dropdown-mobile__wrapper--active')

    await wrapper.find('.nav-bar-dropdown-toggle').trigger('click')
    expect(wrapper.find('.ct-nav-bar-dropdown-mobile__wrapper').classes())
      .toContain('ct-nav-bar-dropdown-mobile__wrapper--active')

    await wrapper.find('.nav-bar-dropdown-toggle').trigger('click')
    expect(wrapper.find('.ct-nav-bar-dropdown-mobile__wrapper').classes())
      .not.toContain('ct-nav-bar-dropdown-mobile__wrapper--active')
  })

  it('ignores hover, since mobile has no hover', async () => {
    const wrapper = mount(NavBarDropdownMobile, { props: { link } })

    await wrapper.trigger('mouseenter')
    expect(wrapper.find('.ct-nav-bar-dropdown-mobile__wrapper').classes())
      .not.toContain('ct-nav-bar-dropdown-mobile__wrapper--active')
  })

  it('closes when clicking outside the dropdown', async () => {
    const wrapper = mount(NavBarDropdownMobile, { props: { link }, attachTo: document.body })

    await wrapper.find('.nav-bar-dropdown-toggle').trigger('click')
    expect(wrapper.find('.ct-nav-bar-dropdown-mobile__wrapper').classes())
      .toContain('ct-nav-bar-dropdown-mobile__wrapper--active')

    // vueuse's onClickOutside briefly guards against double-firing for the same
    // click sequence (touch+click), so a synchronous second click right after the
    // first is ignored — let a macrotask pass first, same as a real user would.
    await new Promise(resolve => setTimeout(resolve, 0))

    document.body.click()
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.ct-nav-bar-dropdown-mobile__wrapper').classes())
      .not.toContain('ct-nav-bar-dropdown-mobile__wrapper--active')

    wrapper.unmount()
  })

  it('closes on Escape keypress', async () => {
    const wrapper = mount(NavBarDropdownMobile, { props: { link }, attachTo: document.body })

    await wrapper.find('.nav-bar-dropdown-toggle').trigger('click')
    expect(wrapper.find('.ct-nav-bar-dropdown-mobile__wrapper').classes())
      .toContain('ct-nav-bar-dropdown-mobile__wrapper--active')

    await wrapper.trigger('keydown', { key: 'Escape' })
    expect(wrapper.find('.ct-nav-bar-dropdown-mobile__wrapper').classes())
      .not.toContain('ct-nav-bar-dropdown-mobile__wrapper--active')

    wrapper.unmount()
  })
})
