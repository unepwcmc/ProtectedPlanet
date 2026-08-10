import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import NavBarMobile from '@/components/NavBar/Mobile.vue'

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

describe('NavBarMobile', () => {
  it('renders a link and a dropdown for a link with children', () => {
    const wrapper = mount(NavBarMobile, { props: { links } })

    expect(wrapper.findAll('.ct-nav-bar-mobile__item')).toHaveLength(2)
    expect(wrapper.find('.ct-nav-bar-link').exists()).toBe(true)
    expect(wrapper.find('.ct-nav-bar-dropdown-mobile').exists()).toBe(true)
  })

  it('opens and closes the pane via the burger and close buttons', async () => {
    const wrapper = mount(NavBarMobile, { props: { links }, attachTo: document.body })

    expect(wrapper.find('.ct-nav-bar-mobile__pane').classes()).not.toContain('ct-nav-bar-mobile__pane--active')

    await wrapper.find('.ct-nav-bar-mobile__burger').trigger('click')
    expect(wrapper.find('.ct-nav-bar-mobile__pane').classes()).toContain('ct-nav-bar-mobile__pane--active')

    await wrapper.find('.ct-nav-bar-mobile__close').trigger('click')
    expect(wrapper.find('.ct-nav-bar-mobile__pane').classes()).not.toContain('ct-nav-bar-mobile__pane--active')

    wrapper.unmount()
  })

  it('locks background scroll while the pane is open, restores it on close', async () => {
    const wrapper = mount(NavBarMobile, { props: { links }, attachTo: document.body })

    expect(document.body.style.overflow).toBe('')

    await wrapper.find('.ct-nav-bar-mobile__burger').trigger('click')
    expect(document.body.style.overflow).toBe('hidden')

    await wrapper.find('.ct-nav-bar-mobile__close').trigger('click')
    expect(document.body.style.overflow).toBe('')

    wrapper.unmount()
  })

  it('closes the pane when clicking outside', async () => {
    const wrapper = mount(NavBarMobile, { props: { links }, attachTo: document.body })

    await wrapper.find('.ct-nav-bar-mobile__burger').trigger('click')
    expect(wrapper.find('.ct-nav-bar-mobile__pane').classes()).toContain('ct-nav-bar-mobile__pane--active')

    // vueuse's onClickOutside briefly guards against double-firing for the same
    // click sequence (touch+click), so a synchronous second click right after the
    // first is ignored — let a macrotask pass first, same as a real user would.
    await new Promise(resolve => setTimeout(resolve, 0))

    document.body.click()
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.ct-nav-bar-mobile__pane').classes()).not.toContain('ct-nav-bar-mobile__pane--active')

    wrapper.unmount()
  })

  it('toggles dropdowns on click, since mobile has no hover', async () => {
    const wrapper = mount(NavBarMobile, { props: { links } })

    await wrapper.find('.nav-bar-dropdown-toggle').trigger('click')
    expect(wrapper.find('.ct-nav-bar-dropdown-mobile__wrapper').classes())
      .toContain('ct-nav-bar-dropdown-mobile__wrapper--active')

    await wrapper.find('.nav-bar-dropdown-toggle').trigger('click')
    expect(wrapper.find('.ct-nav-bar-dropdown-mobile__wrapper').classes())
      .not.toContain('ct-nav-bar-dropdown-mobile__wrapper--active')
  })
})
