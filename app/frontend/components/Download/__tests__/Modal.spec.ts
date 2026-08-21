import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import DownloadModal from '@/components/Download/Modal.vue'
import { useDownloads, resetDownloads } from '@/composables/useDownloads'

const props = {
  endpointCreate: '/downloads',
  endpointPoll: '/downloads/poll',
  gaId: 'Download modal',
  textDownload: { citationText: 'Cite this', citationTitle: 'Citation', title: 'Downloads' },
  textStatus: { download: 'Download', failed: 'Failed', generating: 'Generating...' }
}

function mountModal() {
  return mount(DownloadModal, {
    props,
    global: { stubs: { DownloadItem: true } }
  })
}

beforeEach(() => {
  localStorage.clear()
  sessionStorage.clear()
  resetDownloads()
})

describe('DownloadModal', () => {
  it('is inactive by default and shows the citation copy', () => {
    const wrapper = mountModal()

    expect(wrapper.find('.ct-download-modal').classes()).not.toContain('ct-download-modal--active')
    expect(wrapper.text()).toContain('Downloads')
    expect(wrapper.html()).toContain('Cite this')
  })

  it('becomes active and renders an item per download when the store gains one', async () => {
    const store = useDownloads()
    const wrapper = mountModal()

    store.addNewDownloadItem({ domain: 'protected_area', format: 'csv', token: 'abc' })
    await wrapper.vm.$nextTick()

    expect(wrapper.find('.ct-download-modal').classes()).toContain('ct-download-modal--active')
    expect(wrapper.find('.ct-download-modal__list').findAll('download-item-stub')).toHaveLength(1)
  })

  it('closes and un-minimises itself once the last item is deleted', async () => {
    const store = useDownloads()
    const item = store.addNewDownloadItem({ domain: 'protected_area', format: 'csv', token: 'abc' })
    store.minimiseDownloadModal(true)
    const wrapper = mountModal()

    store.deleteDownloadItem(item)
    await wrapper.vm.$nextTick()

    expect(store.isModalActive).toBe(false)
    expect(store.isModalMinimised).toBe(false)
  })

  it('toggles minimised state when the topbar is clicked', async () => {
    const store = useDownloads()
    const wrapper = mountModal()

    await wrapper.find('.ct-download-modal__minimise').trigger('click')
    expect(store.isModalMinimised).toBe(true)

    await wrapper.find('.ct-download-modal__minimise').trigger('click')
    expect(store.isModalMinimised).toBe(false)
  })

  it('shows downloads a different tab requested, which this tab\'s own modal state knows nothing about', () => {
    localStorage.setItem('downloadItems', JSON.stringify([
      { id: 'from-b', domain: 'protected_area', format: 'pdf', token: 'z', createdAt: Date.now() }
    ]))

    const store = useDownloads()
    const wrapper = mountModal()

    expect(store.downloadItems).toHaveLength(1)
    expect(store.isModalActive).toBe(true)
    expect(wrapper.find('.ct-download-modal').classes()).toContain('ct-download-modal--active')
  })
})
