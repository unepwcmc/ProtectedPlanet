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

  it('chooses an option with Enter and with Space, and marks the chosen one selected', async () => {
    const wrapper = mount(Dropdown, { props: { options: ['a', 'b'], modelValue: 'a' } })

    await wrapper.find('.ct-dropdown-base__button').trigger('click')
    const options = wrapper.findAll('.ct-dropdown-options__option')
    expect(options[0].attributes('aria-selected')).toBe('true')
    expect(options[1].attributes('aria-selected')).toBe('false')
    expect(options[1].attributes('tabindex')).toBe('0')

    await options[1].trigger('keydown', { key: 'Enter' })
    expect(wrapper.emitted('update:modelValue')?.[0]).toEqual(['b'])

    await wrapper.find('.ct-dropdown-base__button').trigger('click')
    await wrapper.findAll('.ct-dropdown-options__option')[0].trigger('keydown', { key: ' ' })
    expect(wrapper.emitted('update:modelValue')?.[1]).toEqual(['a'])
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
