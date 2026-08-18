import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import CarouselThemesIndex from '@/components/Carousel/Themes/Index.vue'

const CARDS = [1, 2, 3, 4].map(n => ({
  url: `/theme-${n}`,
  linkTitle: `View theme ${n}`,
  label: `Theme ${n}`,
  imageUrl: `/theme-${n}.jpg`,
  summary: `Summary ${n}`,
  pasNo: n * 10,
  slug: `theme-${n}`
}))

beforeEach(() => {
  // Swiper measures slide/container dimensions during mount; jsdom's default
  // (all-zero) getBoundingClientRect/offsetWidth are fine functionally, but a
  // real width avoids Swiper's own "no width, can't compute" warnings.
  vi.spyOn(Element.prototype, 'getBoundingClientRect').mockReturnValue({
    width: 300, height: 300, top: 0, left: 0, right: 0, bottom: 0, x: 0, y: 0, toJSON: () => {}
  } as DOMRect)

  // jsdom doesn't implement matchMedia at all; Swiper's `breakpoints` feature
  // calls it directly to decide which breakpoint is active, so mounting
  // throws without this stub. `matches: false` is fine for these tests —
  // they don't assert breakpoint-specific behaviour.
  vi.stubGlobal('matchMedia', vi.fn().mockImplementation((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn()
  })))
})

afterEach(() => {
  vi.restoreAllMocks()
  vi.unstubAllGlobals()
})

describe('Carousel/Themes/Index', () => {
  it('renders every card', () => {
    const wrapper = mount(CarouselThemesIndex, { props: { cards: CARDS, areaTypeLabel: 'protected areas' } })

    // Not asserting DOM order: Swiper's `loop: true` is free to reorder/
    // duplicate slides internally for its own wrap-around illusion — that's
    // its concern, not this component's. What matters here is that every
    // card's data made it into a slide somewhere.
    const cellsText = wrapper.findAll('.ct-carousel-themes__cell').map(cell => cell.text())
    CARDS.forEach((card) => {
      expect(cellsText.some(text => text.includes(card.label))).toBe(true)
    })
  })

  it('does not render when there are no cards', () => {
    const wrapper = mount(CarouselThemesIndex, { props: { cards: [], areaTypeLabel: 'protected areas' } })

    expect(wrapper.find('.ct-carousel-themes').exists()).toBe(false)
  })

  it('renders accessible previous/next controls', () => {
    const wrapper = mount(CarouselThemesIndex, { props: { cards: CARDS, areaTypeLabel: 'protected areas' } })

    expect(wrapper.find('.ct-carousel-themes__button--previous').attributes('aria-label')).toBe('Previous slide')
    expect(wrapper.find('.ct-carousel-themes__button--next').attributes('aria-label')).toBe('Next slide')
  })
})
