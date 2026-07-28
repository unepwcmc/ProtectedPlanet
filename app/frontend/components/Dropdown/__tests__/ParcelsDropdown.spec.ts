import { describe, it, expect, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import AttributesParcelsDropdown from '@/components/Dropdown/ParcelsDropdown.vue'

afterEach(() => {
  window.history.replaceState({}, '', '/protected-areas/123')
})

describe('AttributesParcelsDropdown', () => {
  it('does not render when there is only one parcel', () => {
    const wrapper = mount(AttributesParcelsDropdown, {
      props: { title: 'Choose a parcel', sitePids: ['1234_1'], forPdf: false }
    })

    expect(wrapper.find('.card--feault-block').exists()).toBe(false)
  })

  it('does not render when forPdf is true, even with multiple parcels', () => {
    const wrapper = mount(AttributesParcelsDropdown, {
      props: { title: 'Choose a parcel', sitePids: ['1234_1', '1234_2'], forPdf: true }
    })

    expect(wrapper.find('.card--feault-block').exists()).toBe(false)
  })

  it('defaults to the first parcel and writes it to the URL on mount', async () => {
    const wrapper = mount(AttributesParcelsDropdown, {
      props: { title: 'Choose a parcel', sitePids: ['1234_1', '1234_2'], forPdf: false }
    })
    await wrapper.vm.$nextTick()

    expect(wrapper.find('.ct-dropdown__chosen-value').text()).toBe('1234_1')
    expect(window.location.search).toBe('?site_pid=1234_1')
  })

  it('picks up an existing site_pid from the URL if it is a valid parcel', async () => {
    window.history.replaceState({}, '', '/protected-areas/123?site_pid=1234_2')

    const wrapper = mount(AttributesParcelsDropdown, {
      props: { title: 'Choose a parcel', sitePids: ['1234_1', '1234_2'], forPdf: false }
    })
    await wrapper.vm.$nextTick()

    expect(wrapper.find('.ct-dropdown__chosen-value').text()).toBe('1234_2')
  })

  it('updates the URL when a new parcel is chosen', async () => {
    const wrapper = mount(AttributesParcelsDropdown, {
      props: { title: 'Choose a parcel', sitePids: ['1234_1', '1234_2'], forPdf: false }
    })

    await wrapper.find('.ct-dropdown__button').trigger('click')
    await wrapper.findAll('.ct-dropdown-options__option')[1].trigger('click')

    expect(window.location.search).toBe('?site_pid=1234_2')
  })

  it('shows the description only when there is more than one parcel', () => {
    const single = mount(AttributesParcelsDropdown, {
      props: { title: 'Choose a parcel', description: 'Pick one', sitePids: ['1234_1'], forPdf: false }
    })
    expect(single.text()).not.toContain('Pick one')

    const multiple = mount(AttributesParcelsDropdown, {
      props: { title: 'Choose a parcel', description: 'Pick one', sitePids: ['1234_1', '1234_2'], forPdf: false }
    })
    expect(multiple.text()).toContain('Pick one')
  })
})
