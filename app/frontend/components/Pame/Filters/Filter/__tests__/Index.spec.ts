import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import Filter from '@/components/Pame/Filters/Filter/Index.vue'
import { usePameStore } from '@/stores/usePameStore'

const props = {
  name: 'method',
  title: 'Method',
  options: ['Aerial survey', 'Site visit'],
  isOpen: true
}

beforeEach(() => {
  setActivePinia(createPinia())
})

describe('Pame Filters Filter', () => {
  it('emits toggle when the title button is clicked', async () => {
    const wrapper = mount(Filter, { props })

    await wrapper.find('.filter__button').trigger('click')

    expect(wrapper.emitted('toggle')).toHaveLength(1)
  })

  it('emits apply with only the checked options, and closes', async () => {
    const wrapper = mount(Filter, { props })

    await wrapper.findAll('.filter__checkbox')[0].setValue(true)
    await wrapper.find('.filter__button-apply').trigger('click')

    expect(wrapper.emitted('apply')?.[0]).toEqual([['Aerial survey']])
    expect(wrapper.emitted('toggle')).toHaveLength(1)
  })

  it('reverts pending checkboxes to the last applied state on cancel', async () => {
    const wrapper = mount(Filter, { props })

    await wrapper.findAll('.filter__checkbox')[0].setValue(true)
    await wrapper.find('.filter__button-apply').trigger('click')

    await wrapper.findAll('.filter__checkbox')[1].setValue(true)
    await wrapper.find('.filter__button-cancel').trigger('click')

    const checked = wrapper.findAll('.filter__checkbox').map(el => (el.element as HTMLInputElement).checked)
    expect(checked).toEqual([true, false])
    expect(wrapper.emitted('apply')).toHaveLength(1)
  })

  it('clear empties the pending checkboxes without closing or applying', async () => {
    const wrapper = mount(Filter, { props })

    await wrapper.findAll('.filter__checkbox')[0].setValue(true)
    await wrapper.find('.filter__button-clear').trigger('click')

    const checked = wrapper.findAll('.filter__checkbox').map(el => (el.element as HTMLInputElement).checked)
    expect(checked).toEqual([false, false])
    expect(wrapper.emitted('toggle')).toBeUndefined()
    expect(wrapper.emitted('apply')).toBeUndefined()
  })

  it('does not render when there are no options', () => {
    const wrapper = mount(Filter, { props: { ...props, options: [] } })

    expect(wrapper.find('.filter').exists()).toBe(false)
  })

  it('disables toggle and apply while a PAME request is in flight', async () => {
    usePameStore().setFetching(true)
    const wrapper = mount(Filter, { props })

    expect(wrapper.find('.filter__button-apply').attributes('disabled')).toBeDefined()

    await wrapper.find('.filter__button').trigger('click')

    expect(wrapper.emitted('toggle')).toBeUndefined()
  })
})
