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
  // Download/Index.vue controls visibility with `v-if`, so this component has
  // no `isActive` of its own and always renders once mounted.
  it('renders its content when mounted', () => {
    const wrapper = mount(DownloadCommercial, { props: { text } })
    expect(wrapper.find('.ct-download-commercial').exists()).toBe(true)
  })

  it('emits close when the close icon is clicked', async () => {
    const wrapper = mount(DownloadCommercial, { props: { text } })
    await wrapper.find('.ct-download-commercial__close').trigger('click')
    expect(wrapper.emitted('close')).toHaveLength(1)
  })

  it('emits nonCommercial when the non-commercial button is clicked', async () => {
    const wrapper = mount(DownloadCommercial, { props: { text } })
    await wrapper.find('.ct-download-commercial__link-button').trigger('click')
    expect(wrapper.emitted('nonCommercial')).toHaveLength(1)
  })
})
