import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchResultsItem from '@/components/Search/Results/Item.vue'

describe('SearchResultsItem', () => {
  it('renders title, summary, image and url', () => {
    const wrapper = mount(SearchResultsItem, {
      props: { title: 'Yosemite', summary: 'A national park', image: '/img.jpg', url: '/protected-areas/1' }
    })

    expect(wrapper.find('.ct-search-results-item__title').html()).toContain('Yosemite')
    expect(wrapper.find('.ct-search-results-item__summary').html()).toContain('A national park')
    expect(wrapper.find('.ct-search-results-item__image').attributes('style')).toContain('/img.jpg')
    expect(wrapper.attributes('href')).toBe('/protected-areas/1')
  })

  it('omits the summary paragraph when absent', () => {
    const wrapper = mount(SearchResultsItem, { props: { title: 'Yosemite', url: '/protected-areas/1' } })

    expect(wrapper.find('.ct-search-results-item__summary').exists()).toBe(false)
  })

  it('renders a placeholder icon when no image is given', () => {
    const wrapper = mount(SearchResultsItem, { props: { title: 'Yosemite', url: '/protected-areas/1' } })

    expect(wrapper.find('.ct-search-results-item__placeholder-icon').exists()).toBe(true)
  })
})
