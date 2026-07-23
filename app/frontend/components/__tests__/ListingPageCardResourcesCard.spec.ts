import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ListingPageCardResources from '@/components/ListingPageCard/Resources/Card.vue'

describe('ListingPageCardResourcesCard', () => {
  it('renders as a link when url is present', () => {
    const wrapper = mount(ListingPageCardResources, {
      props: { date: '2026', summary: 'Summary', title: 'Title', url: '/resource/1' }
    })

    expect(wrapper.classes()).toContain('card--link')
    const link = wrapper.find('a.card__link')
    expect(link.attributes('href')).toBe('/resource/1')
    expect(link.attributes('title')).toBe('Title')
    expect(link.find('.card__h3').text()).toBe('Title')
  })

  it('renders download/external-link buttons instead of a card link when url is absent', () => {
    const wrapper = mount(ListingPageCardResources, {
      props: {
        date: '2026',
        fileUrl: '/files/report.pdf',
        linkTitle: 'View external',
        linkUrl: 'https://example.org',
        summary: 'Summary',
        title: 'Title'
      }
    })

    expect(wrapper.classes()).not.toContain('card--link')
    expect(wrapper.find('a.card__link').exists()).toBe(false)

    const download = wrapper.find('a.button--download')
    expect(download.attributes('href')).toBe('/files/report.pdf')
    expect(download.attributes('title')).toBe('Title')

    const external = wrapper.find('a.button--link-external')
    expect(external.attributes('href')).toBe('https://example.org')
    expect(external.text()).toBe('View external')
  })

  it('renders neither button when there is no file or external link', () => {
    const wrapper = mount(ListingPageCardResources, {
      props: { title: 'Title' }
    })

    expect(wrapper.find('a.button--download').exists()).toBe(false)
    expect(wrapper.find('a.button--link-external').exists()).toBe(false)
  })
})
