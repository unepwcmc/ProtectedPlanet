import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchSiteResultsItem from '@/components/Search/Results/Item.vue'

describe('SearchSiteResultsItem', () => {
  it('renders title, summary, image and url', () => {
    const wrapper = mount(SearchSiteResultsItem, {
      props: { title: 'Yosemite', summary: 'A national park', image: '/img.jpg', url: '/protected-areas/1' }
    })

    expect(wrapper.find('.card__title').html()).toContain('Yosemite')
    expect(wrapper.find('.card__summary').html()).toContain('A national park')
    expect(wrapper.find('.card__image').attributes('style')).toContain('/img.jpg')
    expect(wrapper.attributes('href')).toBe('/protected-areas/1')
  })

  it('omits the summary paragraph when absent', () => {
    const wrapper = mount(SearchSiteResultsItem, { props: { title: 'Yosemite', url: '/protected-areas/1' } })

    expect(wrapper.find('.card__summary').exists()).toBe(false)
  })
})
