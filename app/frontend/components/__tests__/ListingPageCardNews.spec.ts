import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ListingPageCardNews from '@/components/ListingPageCard/News/Index.vue'

describe('ListingPageCardNews', () => {
  it('renders one card per item', () => {
    const wrapper = mount(ListingPageCardNews, {
      props: {
        cards: [
          { title: 'First headline', url: '/news/1' },
          { title: 'Second headline', url: '/news/2' }
        ]
      }
    })

    const cards = wrapper.findAll('.ct-listing-page-card-news-card')
    expect(cards).toHaveLength(2)
    expect(cards[0].find('.ct-listing-page-card-news-card__title').text()).toBe('First headline')
    expect(cards[1].find('.ct-listing-page-card-news-card__title').text()).toBe('Second headline')
  })

  it('renders nothing when there are no cards', () => {
    const wrapper = mount(ListingPageCardNews, {
      props: { cards: [] }
    })

    expect(wrapper.findAll('.ct-listing-page-card-news-card')).toHaveLength(0)
  })
})
