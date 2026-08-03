import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import RegionCountryPages from '@/components/RegionCountryPages/Index.vue'

// AmChartPie's own chart-building behaviour is covered by AmChart/__tests__/Pie.spec.ts;
// stubbed here since a real amCharts5 Root needs a canvas jsdom doesn't implement.
const global = { stubs: { AmChartPie: true } }

function buildDatabase(overrides: Record<string, unknown> = {}) {
  return {
    coverage: [
      {
        protected_km2: '1,000', protected_percentage: 20, text_coverage: 'coverage',
        text_protected: 'protected', text_total: 'total', title: 'Land', total_km2: '5,000', type: 'land'
      },
      {
        protected_km2: '200', protected_percentage: 10, text_coverage: 'coverage',
        text_protected: 'protected', text_total: 'total', title: 'Marine', total_km2: '2,000', type: 'marine'
      }
    ],
    message: { text: 'Warning message' },
    ...overrides
  }
}

describe('RegionCountryPages', () => {
  it('does not render the tab strip when there is only one tab', () => {
    const wrapper = mount(RegionCountryPages, {
      props: { data: { wdpa: buildDatabase() }, tabs: [{ id: 'wdpa', title: 'WDPA' }] },
      global
    })

    expect(wrapper.find('.card--stats-toggle').exists()).toBe(false)
  })

  it('switches the active database when a tab is clicked', async () => {
    const wrapper = mount(RegionCountryPages, {
      props: {
        data: {
          wdpa: buildDatabase({ message: { text: 'WDPA message' } }),
          wdpa_oecm: buildDatabase({ message: { text: 'WDPA+OECM message' } })
        },
        tabs: [{ id: 'wdpa', title: 'WDPA' }, { id: 'wdpa_oecm', title: 'WDPA+OECM' }]
      },
      global
    })

    expect(wrapper.text()).toContain('WDPA message')

    await wrapper.findAll('li')[1].trigger('click')

    expect(wrapper.text()).toContain('WDPA+OECM message')
  })

  it('remaps snake_case coverage fields to StatsCoverage props', () => {
    const wrapper = mount(RegionCountryPages, {
      props: { data: { wdpa: buildDatabase() }, tabs: [{ id: 'wdpa', title: 'WDPA' }] },
      global
    })

    expect(wrapper.text()).toContain('1,000km²')
    expect(wrapper.text()).toContain('200km²')
  })

  it('hides coverage/designations/sources/sites when below their thresholds', () => {
    const wrapper = mount(RegionCountryPages, {
      props: {
        data: {
          wdpa: buildDatabase({
            coverage: [{ // only one entry — hasCoverageStats requires > 1
              protected_km2: '1', protected_percentage: 1, text_coverage: 'c',
              text_protected: 'p', text_total: 't', title: 'Land', total_km2: '1', type: 'land'
            }],
            sources: { count: 0, source_updated: 'Updated', sources: [], title: 'Sources' },
            sites: { site_details: [], text_view_all: 'All', title: 'Sites', view_all: '/sites' }
          })
        },
        tabs: [{ id: 'wdpa', title: 'WDPA' }]
      },
      global
    })

    // hasCoverageStats requires > 1 entries, so no per-coverage cards render —
    // the wrapper div itself (also used by iucn/governance) still does.
    expect(wrapper.findAll('.card--stats-coverage')).toHaveLength(0)
    expect(wrapper.find('.list--underline-sources').exists()).toBe(false)
    expect(wrapper.find('.cards--search-results-areas').exists()).toBe(false)
  })

  it('renders relatedCountriesHtml as trusted HTML when present', () => {
    const wrapper = mount(RegionCountryPages, {
      props: {
        data: { wdpa: buildDatabase() },
        tabs: [{ id: 'wdpa', title: 'WDPA' }],
        relatedCountriesHtml: '<div class="card--stats-related">Related</div>'
      },
      global
    })

    expect(wrapper.find('.card--stats-related').text()).toBe('Related')
  })
})
