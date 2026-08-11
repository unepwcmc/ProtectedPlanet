import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import DownloadCommercial from '@/components/Download/Commercial.vue'

const text = {
  commercialText: 'Commercial text',
  commercialTitle: 'Commercial title',
  nonCommercialText: 'Non-commercial text',
  nonCommercialTitle: 'Non-commercial title',
  nonCommercialButton: 'Continue non-commercially',
  title: 'Modal title'
}

describe('DownloadCommercial', () => {
  it('is not rendered by default and renders when isActive is true', () => {
    const inactive = mount(DownloadCommercial, { props: { text } })
    expect(inactive.find('.ct-download-commercial').exists()).toBe(false)

    const active = mount(DownloadCommercial, { props: { text, isActive: true } })
    expect(active.find('.ct-download-commercial').exists()).toBe(true)
  })

  it('emits close when the close icon is clicked', async () => {
    const wrapper = mount(DownloadCommercial, { props: { text, isActive: true } })
    await wrapper.find('.ct-download-commercial__close').trigger('click')
    expect(wrapper.emitted('close')).toHaveLength(1)
  })

  it('emits nonCommercial when the non-commercial button is clicked', async () => {
    const wrapper = mount(DownloadCommercial, { props: { text, isActive: true } })
    await wrapper.find('.ct-download-commercial__link-button').trigger('click')
    expect(wrapper.emitted('nonCommercial')).toHaveLength(1)
  })
})
