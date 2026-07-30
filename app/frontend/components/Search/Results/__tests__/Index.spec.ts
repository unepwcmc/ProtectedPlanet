import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchSiteResults from '@/components/Search/Results/Index.vue'

const results = [
  { title: 'Yosemite', url: '/1', summary: 'A park', image: '/img1.jpg' },
  { title: 'Denali', url: '/2', summary: 'Another park', image: '/img2.jpg' }
]

describe('SearchSiteResults', () => {
  it('renders the total count and each result card', () => {
    const wrapper = mount(SearchSiteResults, { props: { results, resultsText: 'results', totalItems: 2 } })

    expect(wrapper.find('.search__total').text()).toBe('(2 results)')
    expect(wrapper.findAll('.card__link')).toHaveLength(2)
  })

  it('hides the total count when there are no results', () => {
    const wrapper = mount(SearchSiteResults, { props: { results: [], resultsText: 'results', totalItems: 0 } })

    expect(wrapper.find('.search__total').isVisible()).toBe(false)
    expect(wrapper.findAll('.card__link')).toHaveLength(0)
  })
})
