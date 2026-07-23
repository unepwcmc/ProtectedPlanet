import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import DownloadPopup from '@/components/Download/Popup.vue'

const options = [
  { isDownload: true, title: 'CSV' },
  { isMap: true, title: 'MPA Map', url: '/MPA_Map.pdf' },
  { title: 'ESRI Web Service', url: 'https://example.com/service' }
]

describe('DownloadPopup', () => {
  it('renders a download option as a clickable span and emits select on click', async () => {
    const wrapper = mount(DownloadPopup, { props: { options } })

    const links = wrapper.findAll('.popup__link')
    expect(links).toHaveLength(3)
    expect(links[0].element.tagName).toBe('SPAN')

    await links[0].trigger('click')
    expect(wrapper.emitted('select')?.[0]).toEqual([options[0]])
  })

  it('renders a map option as a downloadable link', () => {
    const wrapper = mount(DownloadPopup, { props: { options } })
    const link = wrapper.findAll('.popup__link')[1]

    expect(link.element.tagName).toBe('A')
    expect(link.attributes('href')).toBe('/MPA_Map.pdf')
    expect(link.attributes('download')).toBe('MPA Map')
  })

  it('renders any other option as an external link', () => {
    const wrapper = mount(DownloadPopup, { props: { options } })
    const link = wrapper.findAll('.popup__link')[2]

    expect(link.element.tagName).toBe('A')
    expect(link.attributes('target')).toBe('_blank')
    expect(link.attributes('href')).toBe('https://example.com/service')
  })
})
