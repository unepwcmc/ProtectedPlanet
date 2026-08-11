import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchAreasResults from '@/components/SearchAreas/Results/Index.vue'
import PaginationInfinityScroll from '@/components/PaginationInfinityScroll.vue'

class FakeIntersectionObserver {
  observe = vi.fn()
  disconnect = vi.fn()
  unobserve = vi.fn()
}

beforeEach(() => {
  vi.stubGlobal('IntersectionObserver', FakeIntersectionObserver)
})

afterEach(() => {
  vi.unstubAllGlobals()
})

const results = {
  geoType: 'site',
  title: 'Protected areas',
  total: 2,
  totalPages: 1,
  areas: [
    { title: 'Yosemite', url: '/1', image: '/img1.jpg' },
    { title: 'Denali', url: '/2', image: '/img2.jpg' }
  ]
}

describe('SearchAreasResults', () => {
  it('renders the result count and each area card', () => {
    const wrapper = mount(SearchAreasResults, {
      props: { noResultsText: 'No results.', results, smTriggerElement: 'sm-trigger-infinite-scroll' }
    })

    expect(wrapper.find('h2').text()).toBe('Protected areas (2)')
    expect(wrapper.findAll('.ct-search-areas-results-item')).toHaveLength(2)
  })

  it('shows the no-results message when total is zero', () => {
    const wrapper = mount(SearchAreasResults, {
      props: { noResultsText: 'No results.', results: { ...results, total: 0, areas: [] }, smTriggerElement: 'sm-trigger-infinite-scroll' }
    })

    expect(wrapper.find('.ct-search-areas-results__none').text()).toBe('No results.')
    expect(wrapper.findAll('.ct-search-areas-results-item')).toHaveLength(0)
  })

  it('re-emits requestMore from the pagination trigger', async () => {
    const wrapper = mount(SearchAreasResults, {
      props: { noResultsText: 'No results.', results: { ...results, totalPages: 2 }, smTriggerElement: 'sm-trigger-infinite-scroll' }
    })

    await wrapper.findComponent(PaginationInfinityScroll).vm.$emit('requestMore', 2)

    expect(wrapper.emitted('requestMore')).toEqual([[2]])
  })
})
