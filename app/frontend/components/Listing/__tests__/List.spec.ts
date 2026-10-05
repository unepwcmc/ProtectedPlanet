import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import List from '@/components/Listing/List.vue'
import PaginationInfinityScroll from '@/components/PaginationInfinityScroll.vue'

class FakeIntersectionObserver {
  observe = vi.fn()
  disconnect = vi.fn()
  unobserve = vi.fn()
}

beforeEach(() => {
  vi.stubGlobal('IntersectionObserver', FakeIntersectionObserver)
})

const newsResults = {
  total: 2,
  totalPages: 1,
  results: [
    { title: 'First', url: 'first', summary: 'One' },
    { title: 'Second', url: 'second', summary: 'Two' }
  ]
}

describe('Listing List', () => {
  it('renders news cards for the news template', () => {
    const wrapper = mount(List, {
      props: { resetKey: 0, results: newsResults, template: 'news', textNoResults: 'None' }
    })

    expect(wrapper.findAll('.ct-listing-page-card-news-card')).toHaveLength(2)
    expect(wrapper.find('.ct-listing-page-card-resources-card').exists()).toBe(false)
    expect(wrapper.findAll('.ct-listing-page-card-news-card__title')).toHaveLength(2)
  })

  it('renders resource cards for the resources template', () => {
    const wrapper = mount(List, {
      props: { resetKey: 0, results: newsResults, template: 'resources', textNoResults: 'None' }
    })

    expect(wrapper.findAll('.ct-listing-page-card-resources-card')).toHaveLength(2)
    expect(wrapper.find('.ct-listing-page-card-news-card').exists()).toBe(false)
  })

  it('shows the no-results message when total is 0', () => {
    const wrapper = mount(List, {
      props: {
        resetKey: 0,
        results: { total: 0, totalPages: 0, results: [] },
        template: 'news',
        textNoResults: 'No results found'
      }
    })

    const noResults = wrapper.find('.ct-listing-list__no-results')
    expect(noResults.isVisible()).toBe(true)
    expect(noResults.text()).toBe('No results found')
  })

  it('forwards requestMore from the pagination trigger', async () => {
    const wrapper = mount(List, {
      props: { resetKey: 0, results: newsResults, template: 'news', textNoResults: 'None' }
    })

    await wrapper.findComponent(PaginationInfinityScroll).vm.$emit('requestMore', 2)

    expect(wrapper.emitted('requestMore')?.[0]).toEqual([2])
  })
})
