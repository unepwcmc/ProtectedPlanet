import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'

vi.mock('@amcharts/amcharts4/core', () => ({
  create: vi.fn(() => ({ data: null, radius: null, series: { push: vi.fn((s: unknown) => s) }, dispose: vi.fn() })),
  percent: vi.fn((v: number) => v),
  color: vi.fn((v: string) => v)
}))

vi.mock('@amcharts/amcharts4/charts', () => ({
  PieChart: class {},
  PieSeries: class {
    dataFields = {}
    slices = { template: { states: { getKey: () => ({ properties: {} }) }, tooltipText: '' } }
    labels = { template: { disabled: false } }
    ticks = { template: { disabled: false } }
    colors = { list: [] }
    tooltip = { background: {}, label: { padding: vi.fn() } }
  }
}))

const { default: StatsIucnCategories } = await import('@/components/Stats/IucnCategories.vue')

describe('StatsIucnCategories', () => {
  it('rounds the category percentage to 2 decimal places', () => {
    const wrapper = mount(StatsIucnCategories, {
      props: {
        title: 'IUCN categories',
        chart: [],
        categories: [
          { iucn_category_name: 'Ia', count: 3, percentage: 12.34567, link: '/search-areas' }
        ]
      }
    })

    expect(wrapper.find('.list__value').text()).toBe('3, 12.35%')
  })

  it('renders an empty percentage when falsy', () => {
    const wrapper = mount(StatsIucnCategories, {
      props: {
        title: 'IUCN categories',
        chart: [],
        categories: [
          { iucn_category_name: 'Not Reported', count: 1, percentage: 0, link: '/search-areas' }
        ]
      }
    })

    expect(wrapper.find('.list__value').text()).toBe('1, %')
  })
})
