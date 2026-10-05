import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Disclaimer from '@/components/Map/Disclaimer.vue'

describe('Map Disclaimer', () => {
  it('renders nothing when no disclaimer is given', () => {
    const wrapper = mount(Disclaimer, { props: { mapiIsForRegionCountryPA: false } })

    expect(wrapper.find('.ct-map-disclaimer').exists()).toBe(false)
  })

  it('renders the heading and body html when given a disclaimer', () => {
    const wrapper = mount(Disclaimer, {
      props: {
        disclaimer: { heading: 'Notice', body: '<p>Some text</p>' },
        mapiIsForRegionCountryPA: false
      }
    })

    expect(wrapper.find('.ct-map-disclaimer__heading').text()).toBe('Notice')
    expect(wrapper.find('.ct-map-disclaimer__body').html()).toContain('<p>Some text</p>')
    expect(wrapper.find('.ct-map-disclaimer--country-region-pa').exists()).toBe(false)
  })

  it('applies the region/country/PA styling class when mapiIsForRegionCountryPA is true', () => {
    const wrapper = mount(Disclaimer, {
      props: {
        disclaimer: { heading: 'Notice', body: '<p>Some text</p>' },
        mapiIsForRegionCountryPA: true
      }
    })

    expect(wrapper.find('.ct-map-disclaimer--country-region-pa').exists()).toBe(true)
  })
})
