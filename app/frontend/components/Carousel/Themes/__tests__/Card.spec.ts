import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import CarouselThemesCard from '@/components/Carousel/Themes/Card.vue'

const BASE_PROPS = {
  url: '/thematic-areas/marine',
  linkTitle: 'View the Marine page',
  label: 'Marine',
  imageUrl: '/marine.jpg',
  summary: '<p>Ocean coverage</p>',
  pasNo: 1234,
  slug: 'marine-protected-areas',
  areaTypeLabel: 'protected areas'
}

describe('Carousel/Themes/Card', () => {
  it('renders the link, background image, title and summary', () => {
    const wrapper = mount(CarouselThemesCard, { props: BASE_PROPS })

    const link = wrapper.find<HTMLElement>('a.ct-theme-card')
    expect(link.attributes('href')).toBe('/thematic-areas/marine')
    expect(link.attributes('title')).toBe('View the Marine page')
    expect(link.element.style.backgroundImage).toBe('url("/marine.jpg")')
    expect(wrapper.find('.ct-theme-card__title').text()).toBe('Marine')
    expect(wrapper.find('.ct-theme-card__summary').html()).toContain('Ocean coverage')
  })

  it('forwards every prop to the ribbon, including the areaTypeLabel Card.vue itself has no other use for', () => {
    const wrapper = mount(CarouselThemesCard, { props: BASE_PROPS })

    // Ribbon.vue's own spec covers the pasNo/-1 hide behaviour and internal
    // markup in detail — this just confirms Card.vue wires it up at all,
    // with the card-level `ct-theme-card__ribbon` class layered on top.
    const ribbon = wrapper.find('.ct-theme-card__ribbon')
    expect(ribbon.exists()).toBe(true)
    expect(ribbon.text()).toContain('1234')
    expect(ribbon.text()).toContain('protected areas')
  })
})
