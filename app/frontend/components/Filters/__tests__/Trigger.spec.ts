import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import FiltersTrigger from '@/components/Filters/Trigger.vue'

describe('FiltersTrigger', () => {
  it('emits toggle:filterPane on click', async () => {
    const wrapper = mount(FiltersTrigger, { props: { text: 'Filters' } })

    await wrapper.trigger('click')

    expect(wrapper.emitted('toggle:filterPane')).toHaveLength(1)
  })

  it('does not emit when disabled', async () => {
    const wrapper = mount(FiltersTrigger, { props: { isDisabled: true, text: 'Filters' } })

    await wrapper.trigger('click')

    expect(wrapper.emitted('toggle:filterPane')).toBeUndefined()
  })
})
