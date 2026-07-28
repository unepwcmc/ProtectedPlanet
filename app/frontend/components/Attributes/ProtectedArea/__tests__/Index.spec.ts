import { describe, it, expect, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import AttributesProtectedArea from '@/components/Attributes/ProtectedArea/Index.vue'

const attributesList = [
  { site_pid: '1234_1', attributes: [{ title: 'Name', value: 'Parcel One' }] },
  { site_pid: '1234_2', attributes: [{ title: 'Name', value: 'Parcel Two' }] }
]

afterEach(() => {
  window.history.replaceState({}, '', '/protected-areas/123')
})

describe('AttributesProtectedArea', () => {
  it('shows only the selected parcel\'s attributes when not forPdf', () => {
    window.history.replaceState({}, '', '/protected-areas/123?site_pid=1234_2')

    const wrapper = mount(AttributesProtectedArea, {
      props: { title: 'Attributes', forPdf: false, attributesList }
    })

    expect(wrapper.text()).toContain('Parcel Two')
    expect(wrapper.text()).not.toContain('Parcel One')
  })

  it('falls back to the first parcel when no parcel is selected', () => {
    window.history.replaceState({}, '', '/protected-areas/123')

    const wrapper = mount(AttributesProtectedArea, {
      props: { title: 'Attributes', forPdf: false, attributesList }
    })

    expect(wrapper.text()).toContain('Parcel One')
  })

  it('renders every parcel when forPdf is true', () => {
    const wrapper = mount(AttributesProtectedArea, {
      props: { title: 'Attributes', forPdf: true, attributesList }
    })

    expect(wrapper.text()).toContain('Parcel One')
    expect(wrapper.text()).toContain('Parcel Two')
  })
})
