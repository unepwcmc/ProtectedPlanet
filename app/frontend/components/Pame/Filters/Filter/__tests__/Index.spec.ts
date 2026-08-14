import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Filter from '@/components/Pame/Filters/Filter/Index.vue'

const props = {
  name: 'method',
  title: 'Method',
  options: ['Aerial survey', 'Site visit'],
  appliedOptions: [] as string[],
  isFetching: false,
  isOpen: true
}

describe('Pame Filters Filter', () => {
  it('emits toggle when the title button is clicked', async () => {
    const wrapper = mount(Filter, { props })

    await wrapper.find('.ct-pame-filter__button').trigger('click')

    expect(wrapper.emitted('toggle')).toHaveLength(1)
  })

  it('emits apply with only the checked options, and closes', async () => {
    const wrapper = mount(Filter, { props })

    await wrapper.findAll('.ct-pame-filter-option__checkbox')[0].setValue(true)
    await wrapper.find('.ct-pame-filter-mobile__button-apply').trigger('click')

    expect(wrapper.emitted('apply')?.[0]).toEqual([['Aerial survey']])
    expect(wrapper.emitted('toggle')).toHaveLength(1)
  })

  it('reverts pending checkboxes to the applied options on cancel, discarding the unapplied click', async () => {
    const wrapper = mount(Filter, { props: { ...props, appliedOptions: ['Aerial survey'] } })

    await wrapper.findAll('.ct-pame-filter-option__checkbox')[1].setValue(true)
    await wrapper.find('.ct-pame-filter-mobile__button-cancel').trigger('click')

    const checked = wrapper.findAll('.ct-pame-filter-option__checkbox').map(el => (el.element as HTMLInputElement).checked)
    expect(checked).toEqual([true, false])
    expect(wrapper.emitted('apply')).toBeUndefined()
  })

  it('shows the real applied options as checked when reopened, not an empty selection', async () => {
    const wrapper = mount(Filter, { props })

    // Reopening remounts the dropdown (see the `v-if="isOpen"` guarding it) — this is
    // the regression this covers: the reopened dropdown must seed itself from the
    // filter's real applied value, not reset to nothing.
    await wrapper.setProps({ isOpen: false })
    await wrapper.setProps({ isOpen: true, appliedOptions: ['Site visit'] })

    const checked = wrapper.findAll('.ct-pame-filter-option__checkbox').map(el => (el.element as HTMLInputElement).checked)
    expect(checked).toEqual([false, true])
  })

  it('clear empties the pending checkboxes without closing or applying', async () => {
    const wrapper = mount(Filter, { props })

    await wrapper.findAll('.ct-pame-filter-option__checkbox')[0].setValue(true)
    await wrapper.find('.ct-pame-filter-mobile__button-clear').trigger('click')

    const checked = wrapper.findAll('.ct-pame-filter-option__checkbox').map(el => (el.element as HTMLInputElement).checked)
    expect(checked).toEqual([false, false])
    expect(wrapper.emitted('toggle')).toBeUndefined()
    expect(wrapper.emitted('apply')).toBeUndefined()
  })

  it('does not render when there are no options', () => {
    const wrapper = mount(Filter, { props: { ...props, options: [] } })

    expect(wrapper.find('.ct-pame-filter').exists()).toBe(false)
  })

  it('shows a selected-count badge instead of the arrow icon once options are applied', () => {
    const wrapper = mount(Filter, { props: { ...props, appliedOptions: ['Aerial survey', 'Site visit'] } })

    expect(wrapper.find('.ct-pame-filter__button-total').text()).toBe('2')
    expect(wrapper.find('.ct-pame-filter__icon').exists()).toBe(false)
  })

  it('disables toggle and apply while a PAME request is in flight', async () => {
    const wrapper = mount(Filter, { props: { ...props, isFetching: true } })

    expect(wrapper.find('.ct-pame-filter-mobile__button-apply').attributes('disabled')).toBeDefined()

    await wrapper.find('.ct-pame-filter__button').trigger('click')

    expect(wrapper.emitted('toggle')).toBeUndefined()
  })
})
