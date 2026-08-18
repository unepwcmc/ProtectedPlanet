import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import DownloadModal from '@/components/Download/Modal.vue'
import { useDownloadStore } from '@/stores/useDownloadStore'

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
  setActivePinia(createPinia())
  localStorage.clear()
})

describe('DownloadModal', () => {
  it('is inactive by default and shows the citation copy', () => {
    const wrapper = mountModal()

    expect(wrapper.find('.ct-download-modal').classes()).not.toContain('ct-download-modal--active')
    expect(wrapper.text()).toContain('Downloads')
    expect(wrapper.html()).toContain('Cite this')
  })

  it('becomes active and renders an item per download when the store gains one', async () => {
    const store = useDownloadStore()
    const wrapper = mountModal()

    store.addNewDownloadItem({ id: 1, domain: 'protected_area', format: 'csv', token: 'abc' })
    await wrapper.vm.$nextTick()

    expect(wrapper.find('.ct-download-modal').classes()).toContain('ct-download-modal--active')
    expect(wrapper.find('.ct-download-modal__list').findAll('download-item-stub')).toHaveLength(1)
  })

  it('closes and un-minimises itself once the last item is deleted', async () => {
    const store = useDownloadStore()
    store.addNewDownloadItem({ id: 1, domain: 'protected_area', format: 'csv', token: 'abc' })
    store.minimiseDownloadModal(true)
    const wrapper = mountModal()

    store.deleteDownloadItem({ id: 1, domain: 'protected_area', format: 'csv', token: 'abc' })
    await wrapper.vm.$nextTick()

    expect(store.isModalActive).toBe(false)
    expect(store.isModalMinimised).toBe(false)
  })

  it('toggles minimised state when the topbar is clicked', async () => {
    const store = useDownloadStore()
    const wrapper = mountModal()

    await wrapper.find('.ct-download-modal__minimise').trigger('click')
    expect(store.isModalMinimised).toBe(true)

    await wrapper.find('.ct-download-modal__minimise').trigger('click')
    expect(store.isModalMinimised).toBe(false)
  })

  it('restores persisted state from localStorage on mount', () => {
    localStorage.setItem('downloadItems', JSON.stringify([{ id: 9, domain: 'protected_area', format: 'pdf', token: 'z' }]))
    localStorage.setItem('isModalActive', 'true')

    const store = useDownloadStore()
    mountModal()

    expect(store.downloadItems).toEqual([{ id: 9, domain: 'protected_area', format: 'pdf', token: 'z' }])
    expect(store.isModalActive).toBe(true)
  })
})
