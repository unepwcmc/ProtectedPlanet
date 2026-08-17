import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import StatsTooltipInfo from '@/components/Stats/TooltipInfo.vue'

describe('StatsTooltipInfo', () => {
  it('renders the trigger icon and reveals description/designations on click', async () => {
    const wrapper = mount(StatsTooltipInfo, {
      props: {
        description: 'Some description',
        designationsLabel: 'National designations',
        designationsCount: 12
      }
    })

    expect(wrapper.find('svg').exists()).toBe(true)
    // The tooltip target is v-if'd (not merely hidden via style) until active.
    expect(wrapper.find('[role="tooltip"]').exists()).toBe(false)

    await wrapper.find('.ct-tooltip-second__trigger').trigger('click')

    const target = wrapper.find('[role="tooltip"]')
    expect(target.exists()).toBe(true)
    expect(target.text()).toContain('Some description')
    expect(target.text()).toContain('National designations')
    expect(target.text()).toContain('12')
  })
})
