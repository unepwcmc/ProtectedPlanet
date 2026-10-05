import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import CardItem from '@/components/Card/Item.vue'

describe('Card/Item', () => {
  it('renders the link, background image and plain-text title', () => {
    const wrapper = mount(CardItem, {
      props: { title: 'Yosemite', url: '/1', image: '/img.jpg' }
    })

    const link = wrapper.find<HTMLElement>('a.ct-card-item')
    expect(link.attributes('href')).toBe('/1')
    expect(wrapper.find<HTMLElement>('.ct-card-item__image').element.style.backgroundImage).toBe('url("/img.jpg")')
    expect(wrapper.find('.ct-card-item__title').text()).toBe('Yosemite')
    expect(wrapper.find('.ct-card-item__placeholder-icon').exists()).toBe(false)
  })

  it('falls back to the placeholder icon when there is no image', () => {
    const wrapper = mount(CardItem, { props: { title: 'Yosemite', url: '/1' } })

    expect(wrapper.find('.ct-card-item__placeholder-icon').exists()).toBe(true)
  })

  it('renders the title as HTML when titleIsHtml is set', () => {
    const wrapper = mount(CardItem, {
      props: { title: '<mark>Yose</mark>mite', url: '/1', titleIsHtml: true }
    })

    expect(wrapper.find('.ct-card-item__title').html()).toContain('<mark>Yose</mark>mite')
  })

  it('only shows the secondary text when hasSecondaryLine is set and the text is present', () => {
    const withoutFlag = mount(CardItem, {
      props: { title: 'Yosemite', url: '/1', secondaryText: '3 protected areas' }
    })
    expect(withoutFlag.find('.ct-card-item__secondary-text').exists()).toBe(false)

    const withoutText = mount(CardItem, {
      props: { title: 'Yosemite', url: '/1', hasSecondaryLine: true }
    })
    expect(withoutText.find('.ct-card-item__secondary-text').exists()).toBe(false)

    const withBoth = mount(CardItem, {
      props: { title: 'Yosemite', url: '/1', hasSecondaryLine: true, secondaryText: '3 protected areas' }
    })
    expect(withBoth.find('.ct-card-item__secondary-text').html()).toContain('3 protected areas')
  })

  it('sets the optional link title and modifier class', () => {
    const wrapper = mount(CardItem, {
      props: { title: 'Yosemite', url: '/1', linkTitle: 'View more about the site: Yosemite', modifier: 'site' }
    })

    expect(wrapper.attributes('title')).toBe('View more about the site: Yosemite')
    expect(wrapper.classes()).toContain('ct-card-item--site')
  })
})
