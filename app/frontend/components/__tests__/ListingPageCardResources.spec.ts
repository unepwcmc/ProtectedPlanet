import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ListingPageCardResources from '@/components/ListingPageCard/Resources/Index.vue'

describe('ListingPageCardResources', () => {
  it('renders one card per item', () => {
    const wrapper = mount(ListingPageCardResources, {
      props: {
        cards: [
          { title: 'First', url: '/resource/1' },
          { title: 'Second', url: '/resource/2' }
        ]
      }
    })

    const cards = wrapper.findAll('.card')
    expect(cards).toHaveLength(2)
    expect(cards[0].find('.card__h3').text()).toBe('First')
    expect(cards[1].find('.card__h3').text()).toBe('Second')
  })

  it('adds the preview modifier when preview is true', () => {
    const wrapper = mount(ListingPageCardResources, {
      props: { cards: [], preview: true }
    })

    expect(wrapper.classes()).toContain('preview')
  })

  it('omits the preview modifier when preview is false or absent', () => {
    const wrapper = mount(ListingPageCardResources, {
      props: { cards: [] }
    })

    expect(wrapper.classes()).not.toContain('preview')
  })
})
