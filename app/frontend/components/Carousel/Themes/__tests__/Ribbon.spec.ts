import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import CarouselThemesRibbon from '@/components/Carousel/Themes/Ribbon.vue'

// Ribbon.vue takes the full CarouselThemesCardProps shape (it's `v-bind="props"`
// from Card.vue) even though it only reads pasNo/areaTypeLabel itself — the
// rest are passed here just to match the real prop contract and avoid noisy
// "missing required prop" warnings.
const BASE_PROPS = {
  url: '/thematic-areas/marine',
  linkTitle: 'View the Marine page',
  label: 'Marine',
  imageUrl: '/marine.jpg',
  summary: '<p>Ocean coverage</p>',
  slug: 'marine-protected-areas',
  areaTypeLabel: 'protected areas'
}

describe('Carousel/Themes/Ribbon', () => {
  it('shows the pin icon, pa count and area type label when pasNo is present', () => {
    const wrapper = mount(CarouselThemesRibbon, {
      props: { ...BASE_PROPS, pasNo: 1234 }
    })

    expect(wrapper.find('.ct-carousel-themes-ribbon__number').text()).toBe('1234')
    expect(wrapper.find('.ct-carousel-themes-ribbon__label').text()).toBe('protected areas')
    expect(wrapper.classes()).not.toContain('ct-carousel-themes-ribbon--hide')
  })

  it('hides its content (but keeps its own element, just transparent) when pasNo is -1', () => {
    const wrapper = mount(CarouselThemesRibbon, {
      props: { ...BASE_PROPS, pasNo: -1 }
    })

    expect(wrapper.classes()).toContain('ct-carousel-themes-ribbon--hide')
    expect(wrapper.find('.ct-carousel-themes-ribbon__number').exists()).toBe(false)
    expect(wrapper.find('.ct-carousel-themes-ribbon__label').exists()).toBe(false)
  })
})
