import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import NavBarLink from '@/components/NavBar/Link.vue'

describe('NavBarLink', () => {
  it('renders the label, href and id', () => {
    const wrapper = mount(NavBarLink, {
      props: { link: { id: 'home', label: 'Home', url: '/en', is_current_page: false } }
    })

    expect(wrapper.text()).toBe('Home')
    expect(wrapper.attributes('href')).toBe('/en')
    expect(wrapper.attributes('id')).toBe('home')
    expect(wrapper.classes()).not.toContain('is-current-page')
  })

  it('adds is-current-page when the link is active', () => {
    const wrapper = mount(NavBarLink, {
      props: { link: { id: 'home', label: 'Home', url: '/en', is_current_page: true } }
    })

    expect(wrapper.classes()).toContain('is-current-page')
  })
})
