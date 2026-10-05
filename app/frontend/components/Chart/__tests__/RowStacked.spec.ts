import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ChartRowStacked from '@/components/Chart/RowStacked.vue'

describe('ChartRowStacked', () => {
  it('renders one bar per row, sized by percent, hiding the label for zero-percent rows', () => {
    const wrapper = mount(ChartRowStacked, {
      props: { rows: [{ percent: 40 }, { percent: 0 }, { percent: 60 }] }
    })

    const bars = wrapper.findAll('.ct-chart-row-stacked__bar')
    expect(bars).toHaveLength(3)
    expect(bars[0].attributes('style')).toContain('width: 40%')
    expect(bars[1].find('.ct-chart-row-stacked__percent').exists()).toBe(false)
    expect(bars[2].find('.ct-chart-row-stacked__percent').text()).toBe('60%')
  })

  it('applies theme--<theme> only when a theme prop is given', () => {
    const withTheme = mount(ChartRowStacked, { props: { rows: [], theme: 'aqua' } })
    const withoutTheme = mount(ChartRowStacked, { props: { rows: [] } })

    expect(withTheme.classes()).toContain('tw-shared-chart-legend-colour-aqua')
    expect(withoutTheme.classes().some(className => className.startsWith('theme--'))).toBe(false)
  })

  it('renders the title only when given', () => {
    const wrapper = mount(ChartRowStacked, { props: { rows: [], title: 'Designations' } })

    expect(wrapper.find('.ct-chart-row-stacked__title').text()).toBe('Designations')
  })

  it('without a theme, colours each bar from the 12-colour palette and alternates the tooltip above/below by index', () => {
    const wrapper = mount(ChartRowStacked, {
      props: { rows: Array.from({ length: 3 }, () => ({ percent: 10 })) }
    })

    const bars = wrapper.findAll('.ct-chart-row-stacked__bar')
    expect(bars.map(bar => bar.classes())).toEqual([
      ['ct-chart-row-stacked__bar', 'tw-shared-chart-theme-1'],
      ['ct-chart-row-stacked__bar', 'tw-shared-chart-theme-2'],
      ['ct-chart-row-stacked__bar', 'tw-shared-chart-theme-3']
    ])

    const percents = wrapper.findAll('.ct-chart-row-stacked__percent')
    expect(percents[0].classes()).toContain('ct-chart-row-stacked__percent--above')
    expect(percents[1].classes()).toContain('ct-chart-row-stacked__percent--below')
    expect(percents[2].classes()).toContain('ct-chart-row-stacked__percent--above')
  })

  it('with a theme, colours every bar the same and always puts the tooltip above', () => {
    const wrapper = mount(ChartRowStacked, {
      props: { rows: Array.from({ length: 2 }, () => ({ percent: 10 })), theme: 'aqua' }
    })

    const bars = wrapper.findAll('.ct-chart-row-stacked__bar')
    bars.forEach(bar => expect(bar.classes()).toContain('tw-shared-chart-legend-colour-aqua'))

    const percents = wrapper.findAll('.ct-chart-row-stacked__percent')
    percents.forEach(percent => expect(percent.classes()).toContain('ct-chart-row-stacked__percent--above'))
  })
})
