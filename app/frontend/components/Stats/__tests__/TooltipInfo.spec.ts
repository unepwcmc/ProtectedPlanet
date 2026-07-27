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
    expect(wrapper.find('[role="tooltip"]').attributes('style')).toContain('display: none')

    await wrapper.find('.ct-tooltip-second__trigger').trigger('click')

    const target = wrapper.find('[role="tooltip"]')
    expect(target.attributes('style')).not.toContain('display: none')
    expect(target.text()).toContain('Some description')
    expect(target.text()).toContain('National designations')
    expect(target.text()).toContain('12')
  })
})
