import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Options from '@/components/Pame/Filters/Filter/Options.vue'

const props = {
  options: ['Aerial survey', 'Site visit'],
  selectedOptions: ['Site visit'],
  groupId: 'method'
}

describe('Pame Filters Filter Options', () => {
  it('renders one checkbox per option, checked according to selectedOptions', () => {
    const wrapper = mount(Options, { props })
    const checkboxes = wrapper.findAll('.filter__checkbox')

    expect(checkboxes).toHaveLength(2)
    expect((checkboxes[0].element as HTMLInputElement).checked).toBe(false)
    expect((checkboxes[1].element as HTMLInputElement).checked).toBe(true)
  })

  it('emits click with the option and checked state', async () => {
    const wrapper = mount(Options, { props })

    await wrapper.findAll('.filter__checkbox')[0].setValue(true)

    expect(wrapper.emitted('click')?.[0]).toEqual(['Aerial survey', true])
  })
})
