import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import NavBar from '@/components/NavBar/Index.vue'

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

// Mobile/desktop switching is pure CSS (`.ct-nav-bar__mobile`/`.ct-nav-bar__desktop` in
// Index.vue's <style>, `lg:hidden`/`hidden lg:block`) — both trees are always mounted, jsdom
// doesn't evaluate media queries, so these tests only confirm both trees render with the
// breakpoint-toggle class wired on, not actual computed visibility at a given width.
describe('NavBar', () => {
  it('renders both the mobile and desktop nav, each passed the same links', () => {
    const wrapper = mount(NavBar, { props: { links } })

    const mobile = wrapper.find('.ct-nav-bar-mobile')
    const desktop = wrapper.find('.ct-nav-bar-desktop__list')

    expect(mobile.exists()).toBe(true)
    expect(desktop.exists()).toBe(true)
    expect(mobile.findAll('.ct-nav-bar-mobile__item')).toHaveLength(2)
    expect(desktop.findAll('.ct-nav-bar-desktop__item')).toHaveLength(2)
  })

  it('wires the CSS breakpoint-toggle class onto each nav', () => {
    const wrapper = mount(NavBar, { props: { links } })

    expect(wrapper.find('.ct-nav-bar-mobile').classes()).toContain('ct-nav-bar__mobile')
    expect(wrapper.find('.ct-nav-bar-desktop__list').classes()).toContain('ct-nav-bar__desktop')
  })
})
