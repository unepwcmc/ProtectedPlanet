import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ChartTotalCoverageChart from '@/components/Chart/TotalCoverageChart.vue'

describe('ChartTotalCoverageChart', () => {
  it('renders total as the outer bar and coverage as the nested bar', () => {
    const wrapper = mount(ChartTotalCoverageChart, {
      props: {
        total: { legend_colour_class: 'tw-shared-chart-legend-colour-purple', title: 'Purple legend', value: '56.78' },
        coverage: { legend_colour_class: 'tw-shared-chart-legend-colour-aqua', title: 'Aqua legend', value: '12.34' }
      }
    })

    const bar = wrapper.find('.ct-total-coverage-chart__total-bar')
    expect(bar.classes()).toContain('tw-shared-chart-legend-colour-purple')
    expect(bar.attributes('style')).toContain('width: 56.78%')

    const coverageBar = wrapper.find('.ct-total-coverage-chart__coverage-bar')
    expect(coverageBar.classes()).toContain('tw-shared-chart-legend-colour-aqua')
    expect(coverageBar.attributes('style')).toContain('width: 12.34%')

    expect(wrapper.find('.ct-total-coverage-chart__label--coverage').text()).toBe('12.34%')
    expect(wrapper.find('.ct-total-coverage-chart__label--total').text()).toBe('56.78%')
  })

  it('renders one legend entry per bar, coverage first then total', () => {
    const wrapper = mount(ChartTotalCoverageChart, {
      props: {
        total: { legend_colour_class: 'tw-shared-chart-legend-colour-blue', title: 'Blue legend', value: '2' },
        coverage: { legend_colour_class: 'tw-shared-chart-legend-colour-aqua', title: 'Aqua legend', value: '1' }
      }
    })

    const legendItems = wrapper.findAll('.ct-total-coverage-chart__legend')
    expect(legendItems).toHaveLength(2)
    expect(legendItems[0].find('.ct-total-coverage-chart__legend-key').classes()).toContain('tw-shared-chart-legend-colour-aqua')
    expect(legendItems[0].text()).toBe('Aqua legend')
    expect(legendItems[1].find('.ct-total-coverage-chart__legend-key').classes()).toContain('tw-shared-chart-legend-colour-blue')
    expect(legendItems[1].text()).toBe('Blue legend')
  })
})
