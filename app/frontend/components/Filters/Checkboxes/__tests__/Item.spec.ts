import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import FiltersCheckboxesItem from '@/components/Filters/Checkboxes/Item.vue'

const option = { id: 'wdpa', title: 'WDPA' }

describe('FiltersCheckboxesItem', () => {
  it('renders the option title and reflects checked state', () => {
    const wrapper = mount(FiltersCheckboxesItem, { props: { checked: true, groupId: 'topics', option } })

    expect(wrapper.find('input').element.checked).toBe(true)
    expect(wrapper.find('.checkbox__text').text()).toBe('WDPA')
  })

  it('emits click with the new checked value', async () => {
    const wrapper = mount(FiltersCheckboxesItem, { props: { checked: false, groupId: 'topics', option } })

    await wrapper.find('input').setValue(true)

    expect(wrapper.emitted('click')?.[0]).toEqual([true])
  })
})
