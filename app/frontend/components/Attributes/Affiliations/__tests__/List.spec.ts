import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import AttributesAffiliationsList from '@/components/Attributes/Affiliations/List.vue'

const affiliationsByParcel = {
  '1234_1': [
    { site_pid: '1234_1', affiliation: 'greenlist', image_url: '/a.png', link_url: '/a', link_title: 'A' }
  ],
  '1234_2': [
    { site_pid: '1234_2', affiliation: 'parcc', image_url: '/b.png', link_url: '/b', link_title: 'B' }
  ]
}

const translations = {
  green_list_intro: 'Intro',
  green_list_type: 'Type',
  green_list_date: 'Date',
  green_list_title: 'Title',
  green_list_url: 'URL',
  no_information: 'No information available',
  more: 'More'
}

describe('AttributesAffiliationsList', () => {
  it('renders one item per parcel group, sub-titled with the parcel id', () => {
    const wrapper = mount(AttributesAffiliationsList, {
      props: { affiliationsByParcel, forPdf: false, subTitle: 'Parcel ID', translations }
    })

    const subTitles = wrapper.findAll('.ct-attributes-affiliations-list__subtitle').map(el => el.text())
    expect(subTitles).toEqual(['Parcel ID: 1234_1', 'Parcel ID: 1234_2'])
    expect(wrapper.findAll('.ct-attributes-affiliations-affiliation')).toHaveLength(2)
  })
})
