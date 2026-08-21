import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import CarouselThemesRibbon from '@/components/Carousel/Themes/Ribbon.vue'

// Ribbon.vue is `v-bind="props"`'d from Card.vue, so it takes the full
// CarouselThemesCardProps shape though it only reads pasNo/areaTypeLabel. The
// rest are passed to match that contract and silence prop warnings.
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
