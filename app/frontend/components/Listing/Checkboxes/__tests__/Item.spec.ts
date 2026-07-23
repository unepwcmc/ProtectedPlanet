import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import CheckboxesItem from '@/components/Listing/Checkboxes/Item.vue'

const option = { id: 'wdpa', title: 'WDPA' }

describe('Listing Checkboxes Item', () => {
  it('renders the option title and reflects checked state', () => {
    const wrapper = mount(CheckboxesItem, { props: { checked: true, groupId: 'topics', option } })

    expect(wrapper.find('input').element.checked).toBe(true)
    expect(wrapper.find('.checkbox__text').text()).toBe('WDPA')
  })

  it('emits change with the new checked value', async () => {
    const wrapper = mount(CheckboxesItem, { props: { checked: false, groupId: 'topics', option } })

    await wrapper.find('input').setValue(true)

    expect(wrapper.emitted('change')?.[0]).toEqual([true])
  })
})
