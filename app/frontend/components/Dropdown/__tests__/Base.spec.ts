import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Dropdown from '@/components/Dropdown/Base.vue'

describe('Dropdown', () => {
  it('renders the title and the chosen value, falling back to defaultDropdownText', () => {
    const wrapper = mount(Dropdown, {
      props: { title: 'Parcel ID', defaultDropdownText: 'Choose one', options: ['a', 'b'] }
    })

    expect(wrapper.find('.ct-dropdown-base__title').text()).toBe('Parcel ID')
    expect(wrapper.find('.ct-dropdown-base__chosen-value').text()).toBe('Choose one')
  })

  it('opens the options list on click and emits update:modelValue on choice', async () => {
    const wrapper = mount(Dropdown, {
      props: { options: ['a', 'b'], modelValue: undefined }
    })

    expect(wrapper.find('.ct-dropdown-options__options').exists()).toBe(false)

    await wrapper.find('.ct-dropdown-base__button').trigger('click')
    expect(wrapper.find('.ct-dropdown-options__options').exists()).toBe(true)

    await wrapper.findAll('.ct-dropdown-options__option')[1].trigger('click')
    expect(wrapper.emitted('update:modelValue')?.[0]).toEqual(['b'])
    expect(wrapper.find('.ct-dropdown-options__options').exists()).toBe(false)
  })

  it('closes when clicking outside', async () => {
    const wrapper = mount(Dropdown, {
      props: { options: ['a', 'b'] },
      attachTo: document.body
    })

    await wrapper.find('.ct-dropdown-base__button').trigger('click')
    expect(wrapper.find('.ct-dropdown-options__options').exists()).toBe(true)

    await new Promise(resolve => setTimeout(resolve, 0))
    document.body.click()
    await wrapper.vm.$nextTick()

    expect(wrapper.find('.ct-dropdown-options__options').exists()).toBe(false)

    wrapper.unmount()
  })
})
