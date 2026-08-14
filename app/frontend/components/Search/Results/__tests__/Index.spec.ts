import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchResults from '@/components/Search/Results/Index.vue'

const results = [
  { title: 'Yosemite', url: '/1', summary: 'A park', image: '/img1.jpg' },
  { title: 'Denali', url: '/2', summary: 'Another park', image: '/img2.jpg' }
]

describe('SearchResults', () => {
  it('renders the total count and each result card', () => {
    const wrapper = mount(SearchResults, { props: { results, resultsText: 'results', totalItems: 2 } })

    expect(wrapper.find('.ct-search-results__total').text()).toBe('(2 results)')
    expect(wrapper.findAll('.ct-search-results-item')).toHaveLength(2)
  })

  it('hides the total count when there are no results', () => {
    const wrapper = mount(SearchResults, { props: { results: [], resultsText: 'results', totalItems: 0 } })

    expect(wrapper.find('.ct-search-results__total').isVisible()).toBe(false)
    expect(wrapper.findAll('.ct-search-results-item')).toHaveLength(0)
  })
})
