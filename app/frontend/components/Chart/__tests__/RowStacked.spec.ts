import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ChartRowStacked from '@/components/Chart/RowStacked.vue'

describe('ChartRowStacked', () => {
  it('renders one bar per row, sized by percent, hiding the label for zero-percent rows', () => {
    const wrapper = mount(ChartRowStacked, {
      props: { rows: [{ percent: 40 }, { percent: 0 }, { percent: 60 }] }
    })

    const bars = wrapper.findAll('.chart__bar')
    expect(bars).toHaveLength(3)
    expect(bars[0].attributes('style')).toContain('width: 40%')
    expect(bars[1].find('.chart__percent').exists()).toBe(false)
    expect(bars[2].find('.chart__percent').text()).toBe('60%')
  })

  it('applies theme--<theme> only when a theme prop is given', () => {
    const withTheme = mount(ChartRowStacked, { props: { rows: [], theme: 'aqua' } })
    const withoutTheme = mount(ChartRowStacked, { props: { rows: [] } })

    expect(withTheme.classes()).toContain('theme--aqua')
    expect(withoutTheme.classes().some(className => className.startsWith('theme--'))).toBe(false)
  })

  it('renders the title only when given', () => {
    const wrapper = mount(ChartRowStacked, { props: { rows: [], title: 'Designations' } })

    expect(wrapper.find('.chart__title').text()).toBe('Designations')
  })
})
