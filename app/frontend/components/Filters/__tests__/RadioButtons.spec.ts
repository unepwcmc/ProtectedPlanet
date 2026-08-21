import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import FiltersRadioButtons from '@/components/Filters/RadioButtons.vue'

const options = [
  { id: 'wdpa', title: 'WDPA' },
  { id: 'oecm', title: 'OECM' }
]

describe('FiltersRadioButtons', () => {
  it('emits update:options and checks the clicked radio', async () => {
    const wrapper = mount(FiltersRadioButtons, { props: { id: 'db_type', name: 'db_type', options } })

    await wrapper.findAll('input[type="radio"]')[1].trigger('click')

    expect(wrapper.emitted('update:options')?.at(-1)).toEqual(['oecm'])
    expect((wrapper.findAll('input[type="radio"]')[1].element as HTMLInputElement).checked).toBe(true)
  })

  it('emits the preSelected value on mount', () => {
    const wrapper = mount(FiltersRadioButtons, { props: { id: 'db_type', name: 'db_type', options, preSelected: 'oecm' } })

    expect(wrapper.emitted('update:options')?.[0]).toEqual(['oecm'])
    expect((wrapper.findAll('input[type="radio"]')[1].element as HTMLInputElement).checked).toBe(true)
  })

  it('clears the selection and re-emits an empty value when resetKey changes', async () => {
    const wrapper = mount(FiltersRadioButtons, { props: { id: 'db_type', name: 'db_type', options, preSelected: 'wdpa' } })

    await wrapper.setProps({ resetKey: 1 })

    expect(wrapper.emitted('update:options')?.at(-1)).toEqual([''])
    expect((wrapper.findAll('input[type="radio"]')[0].element as HTMLInputElement).checked).toBe(false)
  })

  it('hides itself when there are no options', () => {
    const wrapper = mount(FiltersRadioButtons, { props: { id: 'db_type', name: 'db_type', options: [] } })

    expect(wrapper.find('.ct-filters-radio-buttons').isVisible()).toBe(false)
  })
})
