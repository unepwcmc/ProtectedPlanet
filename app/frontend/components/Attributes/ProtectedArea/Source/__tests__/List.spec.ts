import { describe, it, expect, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import AttributesProtectedAreaSources from '@/components/Attributes/ProtectedArea/Source/List.vue'

const sourcesAttributesList = {
  '1234_1': [{ title: 'Source A', date_updated: '2020', resp_party: 'Party A' }],
  '1234_2': [
    { title: 'Source B', date_updated: '2021', resp_party: 'Party B' },
    { title: 'Source C', date_updated: '2022', resp_party: 'Party C' }
  ]
}

const translations = { title: 'Sources', total: 'Total Sources', updated: 'Updated' }

afterEach(() => {
  window.history.replaceState({}, '', '/protected-areas/123')
})

describe('AttributesProtectedAreaSources', () => {
  it('shows only the selected parcel\'s sources and its count in the heading', () => {
    window.history.replaceState({}, '', '/protected-areas/123?site_pid=1234_2')

    const wrapper = mount(AttributesProtectedAreaSources, {
      props: { sourcesAttributesList, forPdf: false, translations }
    })

    expect(wrapper.find('h2').text()).toBe('Sources (2)')
    expect(wrapper.findAll('.ct-attributes-protected-area-source__item')).toHaveLength(2)
  })

  it('shows the total count across all parcels when forPdf is true', () => {
    const wrapper = mount(AttributesProtectedAreaSources, {
      props: { sourcesAttributesList, forPdf: true, translations }
    })

    expect(wrapper.find('h2').text()).toBe('Sources (3)')
  })
})
