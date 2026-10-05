import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import CardsThemesIndex from '@/components/Cards/Themes/Index.vue'

const CARDS = [1, 2, 3, 4].map(n => ({
  url: `/theme-${n}`,
  linkTitle: `View theme ${n}`,
  label: `Theme ${n}`,
  imageUrl: `/theme-${n}.jpg`,
  summary: `Summary ${n}`,
  pasNo: n * 10,
  slug: `theme-${n}`
}))

describe('Cards/Themes/Index', () => {
  it('renders every card, reusing Carousel/Themes/Card.vue', () => {
    const wrapper = mount(CardsThemesIndex, { props: { cards: CARDS, areaTypeLabel: 'protected areas' } })

    const cells = wrapper.findAll('.ct-cards-themes__cell')
    expect(cells).toHaveLength(CARDS.length)
    CARDS.forEach((card) => {
      expect(cells.some(cell => cell.text().includes(card.label))).toBe(true)
    })
  })

  it('does not render when there are no cards', () => {
    const wrapper = mount(CardsThemesIndex, { props: { cards: [], areaTypeLabel: 'protected areas' } })

    expect(wrapper.find('.ct-cards-themes').exists()).toBe(false)
  })

  it('marks only every 3rd card as featured', () => {
    const wrapper = mount(CardsThemesIndex, { props: { cards: CARDS, areaTypeLabel: 'protected areas' } })

    const featuredFlags = wrapper.findAll('.ct-theme-card').map(card => card.classes('ct-theme-card--featured'))
    expect(featuredFlags).toEqual([false, false, true, false])
  })

  it('spans the full row for the featured cell only, at the two-column breakpoint', () => {
    const wrapper = mount(CardsThemesIndex, { props: { cards: CARDS, areaTypeLabel: 'protected areas' } })

    const cellFlags = wrapper.findAll('.ct-cards-themes__cell').map(cell => cell.classes('ct-cards-themes__cell--featured'))
    expect(cellFlags).toEqual([false, false, true, false])
  })
})
