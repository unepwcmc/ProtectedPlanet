import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import NavBarDesktop from '@/components/NavBar/Desktop.vue'

const links = [
  { id: 'home', label: 'Home', url: '/en', is_current_page: true },
  {
    id: 'data',
    label: 'Data',
    url: '/en/data',
    is_current_page: false,
    children: [{ id: 'wdpa', label: 'WDPA', url: '/en/data/wdpa', is_current_page: false }]
  }
]

describe('NavBarDesktop', () => {
  it('renders a link and a dropdown for a link with children', () => {
    const wrapper = mount(NavBarDesktop, { props: { links } })

    expect(wrapper.findAll('.ct-nav-bar-desktop__item')).toHaveLength(2)
    expect(wrapper.find('.ct-nav-bar-link').exists()).toBe(true)
    expect(wrapper.find('.ct-nav-bar-dropdown-desktop').exists()).toBe(true)
  })

  it('opens dropdowns on hover, not click (desktop has no burger nav)', async () => {
    const wrapper = mount(NavBarDesktop, { props: { links } })

    await wrapper.find('.ct-nav-bar-dropdown-desktop__toggle').trigger('click')
    expect(wrapper.find('.ct-nav-bar-dropdown-desktop').classes()).not.toContain('ct-nav-bar-dropdown-desktop--active')

    await wrapper.find('.ct-nav-bar-dropdown-desktop').trigger('mouseenter')
    expect(wrapper.find('.ct-nav-bar-dropdown-desktop').classes()).toContain('ct-nav-bar-dropdown-desktop--active')
  })
})
