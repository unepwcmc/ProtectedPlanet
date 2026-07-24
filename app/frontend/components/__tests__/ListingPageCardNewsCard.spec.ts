import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ListingPageCardNews from '@/components/ListingPageCard/News/Card.vue'

describe('ListingPageCardNewsCard', () => {
  it('renders title, summary, date and links to the article', () => {
    const wrapper = mount(ListingPageCardNews, {
      props: {
        date: '01 January 26',
        image: '/img/news.png',
        summary: 'A short summary',
        title: 'Some headline',
        url: '/news/1'
      }
    })

    expect(wrapper.attributes('href')).toBe('/news/1')
    expect(wrapper.find('.card__date').text()).toBe('01 January 26')
    expect(wrapper.find('.card__h3').text()).toBe('Some headline')
    expect(wrapper.find('.card__summary').text()).toBe('A short summary')
    expect(wrapper.find('.card__image').attributes('style')).toContain('/img/news.png')
    expect(wrapper.find('.card__icon').exists()).toBe(false)
  })

  it('falls back to a placeholder icon when there is no image', () => {
    const wrapper = mount(ListingPageCardNews, {
      props: { summary: 'Summary', title: 'Title', url: '/news/2' }
    })

    expect(wrapper.find('.card__icon').exists()).toBe(true)
    expect(wrapper.find('.card__date').exists()).toBe(false)
  })
})
