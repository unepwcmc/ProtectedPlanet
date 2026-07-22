import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import NavBarDropdown from '@/components/NavBar/Dropdown.vue'

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

describe('NavBarDropdown', () => {
  it('renders the trigger label and child links', () => {
    const wrapper = mount(NavBarDropdown, { props: { link } })

    expect(wrapper.find('.nav__dropdown-toggle-a').text()).toBe('Data')
    const children = wrapper.findAll('.nav__dropdown-a')
    expect(children).toHaveLength(2)
    expect(children[0].text()).toBe('WDPA')
  })

  it('opens on mouseenter and closes on mouseleave', async () => {
    const wrapper = mount(NavBarDropdown, { props: { link } })

    expect(wrapper.classes()).not.toContain('active')

    await wrapper.trigger('mouseenter')
    expect(wrapper.classes()).toContain('active')

    await wrapper.trigger('mouseleave')
    expect(wrapper.classes()).not.toContain('active')
  })

  it('toggles on touchend (mobile tap, no hover)', async () => {
    const wrapper = mount(NavBarDropdown, { props: { link } })

    await wrapper.find('.nav__dropdown-toggle-a').trigger('touchend')
    expect(wrapper.classes()).toContain('active')

    await wrapper.find('.nav__dropdown-toggle-a').trigger('touchend')
    expect(wrapper.classes()).not.toContain('active')
  })

  it('closes when clicking outside the dropdown', async () => {
    const wrapper = mount(NavBarDropdown, { props: { link }, attachTo: document.body })

    await wrapper.trigger('mouseenter')
    expect(wrapper.classes()).toContain('active')

    document.body.click()
    await wrapper.vm.$nextTick()
    expect(wrapper.classes()).not.toContain('active')

    wrapper.unmount()
  })

  it('closes on Escape keypress', async () => {
    const wrapper = mount(NavBarDropdown, { props: { link }, attachTo: document.body })

    await wrapper.trigger('mouseenter')
    expect(wrapper.classes()).toContain('active')

    await wrapper.trigger('keydown', { key: 'Escape' })
    expect(wrapper.classes()).not.toContain('active')

    wrapper.unmount()
  })
})
