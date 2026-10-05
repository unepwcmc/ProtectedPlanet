import { describe, it, expect, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import AttributesPameList from '@/components/Attributes/Pame/List.vue'

const pamesAttributesList = {
  '1234_1': { METT: [2018, 2020] },
  '1234_2': { RAPPAM: [2019] }
}

const translations = { no_information: 'No information available' }

afterEach(() => {
  window.history.replaceState({}, '', '/protected-areas/123')
})

describe('AttributesPameList', () => {
  it('shows only the selected parcel\'s PAME evaluations', () => {
    window.history.replaceState({}, '', '/protected-areas/123?site_pid=1234_2')

    const wrapper = mount(AttributesPameList, {
      props: { pamesAttributesList, title: 'PAME', forPdf: false, translations }
    })

    expect(wrapper.text()).toContain('RAPPAM')
    expect(wrapper.text()).not.toContain('METT')
  })

  it('falls back to the first parcel when no parcel is selected', () => {
    const wrapper = mount(AttributesPameList, {
      props: { pamesAttributesList, title: 'PAME', forPdf: false, translations }
    })

    expect(wrapper.text()).toContain('METT')
  })

  it('renders every parcel\'s PAME evaluations when forPdf is true', () => {
    const wrapper = mount(AttributesPameList, {
      props: { pamesAttributesList, title: 'PAME', forPdf: true, translations }
    })

    expect(wrapper.text()).toContain('METT')
    expect(wrapper.text()).toContain('RAPPAM')
  })

  it('shows the no-information translation when there is nothing to show', () => {
    const wrapper = mount(AttributesPameList, {
      props: { pamesAttributesList: {}, title: 'PAME', forPdf: false, translations }
    })

    expect(wrapper.text()).toContain('No information available')
  })
})
