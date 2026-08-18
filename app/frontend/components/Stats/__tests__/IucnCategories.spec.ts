import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import StatsIucnCategories from '@/components/Stats/IucnCategories.vue'

// AmChartPie's own chart-building behaviour is covered by AmChart/__tests__/Pie.spec.ts;
// stubbed here since a real amCharts5 Root needs a canvas jsdom doesn't implement.
const stubs = { AmChartPie: true }

describe('StatsIucnCategories', () => {
  it('rounds the category percentage to 2 decimal places', () => {
    const wrapper = mount(StatsIucnCategories, {
      props: {
        title: 'IUCN categories',
        chart: [],
        categories: [
          { iucn_category_name: 'Ia', count: 3, percentage: 12.34567, link: '/search-areas' }
        ]
      },
      global: { stubs }
    })

    expect(wrapper.find('.ct-stats-iucn-categories__item-value').text()).toBe('3, 12.35%')
  })

  it('renders an empty percentage when falsy', () => {
    const wrapper = mount(StatsIucnCategories, {
      props: {
        title: 'IUCN categories',
        chart: [],
        categories: [
          { iucn_category_name: 'Not Reported', count: 1, percentage: 0, link: '/search-areas' }
        ]
      },
      global: { stubs }
    })

    expect(wrapper.find('.ct-stats-iucn-categories__item-value').text()).toBe('1, %')
  })
})
