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

  it('shows the ribbon with the pin icon and pa count when pasNo is present', () => {
    const wrapper = mount(CarouselThemesCard, { props: BASE_PROPS })

    expect(wrapper.find('.ct-theme-card__ribbon').exists()).toBe(true)
    expect(wrapper.find('.ct-theme-card__ribbon-number').text()).toBe('1234')
    expect(wrapper.find('.ct-theme-card__ribbon-label').text()).toBe('protected areas')
  })

  it('hides the ribbon when pasNo is -1', () => {
    const wrapper = mount(CarouselThemesCard, { props: { ...BASE_PROPS, pasNo: -1 } })

    expect(wrapper.find('.ct-theme-card__ribbon').exists()).toBe(false)
  })
})
