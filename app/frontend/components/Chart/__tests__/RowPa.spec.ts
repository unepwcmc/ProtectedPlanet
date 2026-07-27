import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ChartRowPa from '@/components/Chart/RowPa.vue'

describe('ChartRowPa', () => {
  it('renders the bar/coverage widths and labels from props', () => {
    const wrapper = mount(ChartRowPa, {
      props: { coverage: '12.34', percent: '56.78', theme: 'theme--purple' }
    })

    const bar = wrapper.find('.chart__bar')
    expect(bar.classes()).toContain('theme--purple')
    expect(bar.attributes('style')).toContain('width: 56.78%')
    expect(wrapper.find('.chart__coverage').attributes('style')).toContain('width: 12.34%')
    expect(wrapper.find('.chart__coverage-label').text()).toBe('12.34%')
    expect(wrapper.find('.chart__bar-label').text()).toBe('56.78%')
  })

  it('works without a theme', () => {
    const wrapper = mount(ChartRowPa, { props: { coverage: '1', percent: '2' } })

    expect(wrapper.find('.chart__bar').classes()).not.toContain('undefined')
  })
})
