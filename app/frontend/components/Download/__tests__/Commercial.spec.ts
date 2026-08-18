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
  // Commercial.vue no longer owns an `isActive` prop/toggle — the parent
  // (Download/Index.vue) controls visibility itself via `v-if`, so the
  // component always renders its content once mounted.
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
