import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import FilterTrigger from '@/components/Listing/FilterTrigger.vue'

describe('Listing FilterTrigger', () => {
  it('emits toggle:filterPane on click', async () => {
    const wrapper = mount(FilterTrigger, { props: { text: 'Filters' } })

    await wrapper.trigger('click')

    expect(wrapper.emitted('toggle:filterPane')).toHaveLength(1)
  })

  it('does not emit when disabled', async () => {
    const wrapper = mount(FilterTrigger, { props: { isDisabled: true, text: 'Filters' } })

    await wrapper.trigger('click')

    expect(wrapper.emitted('toggle:filterPane')).toBeUndefined()
  })
})
