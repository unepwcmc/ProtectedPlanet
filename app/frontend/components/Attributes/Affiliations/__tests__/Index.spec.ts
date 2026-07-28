import { describe, it, expect, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import AttributesAffiliations from '@/components/Attributes/Affiliations/Index.vue'

const affiliations = [
  { site_pid: '1234_1', affiliation: 'greenlist', image_url: '/a.png', link_url: '/a', link_title: 'A' },
  { site_pid: '1234_2', affiliation: 'parcc', image_url: '/b.png', link_url: '/b', link_title: 'B' }
]

const translations = {
  green_list_intro: 'Intro',
  green_list_type: 'Type',
  green_list_date: 'Date',
  green_list_title: 'Title',
  green_list_url: 'URL',
  no_information: 'No information available',
  more: 'More'
}

afterEach(() => {
  window.history.replaceState({}, '', '/protected-areas/123')
})

describe('AttributesAffiliations', () => {
  it('shows only the selected parcel\'s affiliations', () => {
    window.history.replaceState({}, '', '/protected-areas/123?site_pid=1234_2')

    const wrapper = mount(AttributesAffiliations, {
      props: { affiliations, title: 'Affiliations', forPdf: false, translations }
    })

    expect(wrapper.findAll('.card__logo')).toHaveLength(1)
    expect(wrapper.find('img').attributes('src')).toBe('/b.png')
  })

  it('renders every parcel grouped when forPdf is true', () => {
    const wrapper = mount(AttributesAffiliations, {
      props: { affiliations, title: 'Affiliations', forPdf: true, translations }
    })

    expect(wrapper.findAll('.card__logo')).toHaveLength(2)
  })

  it('shows the no-information translation when there are no affiliations', () => {
    const wrapper = mount(AttributesAffiliations, {
      props: { affiliations: [], title: 'Affiliations', forPdf: false, translations }
    })

    expect(wrapper.text()).toContain('No information available')
  })
})
