import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import AttributeList from '@/components/Attributes/ProtectedArea/AttributeList.vue'

const attributes = [
  { title: 'Parcel ID', value: '1234_1', is_site_pid: true },
  { title: 'Name', value: 'Test Parcel' }
]

describe('AttributeList', () => {
  it('hides the site-pid row by default', () => {
    const wrapper = mount(AttributeList, { props: { attributes, forPdf: false } })

    const titles = wrapper.findAll('.ct-attributes-protected-area-list__item-title').map(t => t.text())
    expect(titles).toEqual(['Name'])
  })

  it('shows the site-pid row when forPdf is true', () => {
    const wrapper = mount(AttributeList, { props: { attributes, forPdf: true } })

    const titles = wrapper.findAll('.ct-attributes-protected-area-list__item-title').map(t => t.text())
    expect(titles).toEqual(['Parcel ID', 'Name'])
  })

  it('renders nothing when attributes is empty', () => {
    const wrapper = mount(AttributeList, { props: { attributes: [], forPdf: false } })
    expect(wrapper.find('ul').exists()).toBe(false)
  })
})
