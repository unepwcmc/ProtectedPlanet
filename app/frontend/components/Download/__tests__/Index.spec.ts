import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import Download from '@/components/Download/Index.vue'
import { useDownloads, resetDownloads } from '@/composables/useDownloads'
import type { DownloadOption } from '@/types/backend'

const textCommercial = {
  commercialText: 'Commercial text',
  commercialTitle: 'Commercial title',
  nonCommercialText: 'Non-commercial text',
  nonCommercialTitle: 'Non-commercial title',
  nonCommercialButton: 'Continue',
  title: 'Modal title'
}

const csvOption: DownloadOption = {
  isDownload: true,
  title: 'CSV',
  commercialAvailable: true,
  params: { domain: 'protected_area', format: 'csv', token: 'abc' }
}

const searchOption: DownloadOption = {
  isDownload: true,
  title: 'CSV',
  commercialAvailable: true,
  params: { domain: 'search', format: 'csv', token: 'abc' }
}

function mountDownload(options: DownloadOption[] = [csvOption]) {
  return mount(Download, {
    props: { buttonText: 'Download', options, textCommercial, gaId: 'test' }
  })
}

beforeEach(() => {
  localStorage.clear()
  sessionStorage.clear()
  resetDownloads()
})

describe('Download', () => {
  it('toggles the option popup on trigger click, unless disabled', async () => {
    const wrapper = mountDownload()

    expect(wrapper.find('.ct-download-popup').exists()).toBe(false)
    await wrapper.find('.ct-download__trigger').trigger('click')
    expect(wrapper.find('.ct-download-popup').exists()).toBe(true)
  })

  it('does not open when downloadDisabled is true', async () => {
    const wrapper = mount(Download, {
      props: { buttonText: 'Download', options: [csvOption], textCommercial, gaId: 'test', downloadDisabled: true }
    })

    expect(wrapper.find('.ct-download__trigger').attributes('disabled')).toBeDefined()
    await wrapper.find('.ct-download__trigger').trigger('click')
    expect(wrapper.find('.ct-download-popup').exists()).toBe(false)
  })

  it('opens the commercial modal for a commercial-available option instead of downloading immediately', async () => {
    const store = useDownloads()
    const wrapper = mountDownload()

    await wrapper.find('.ct-download__trigger').trigger('click')
    await wrapper.find('.ct-download-popup__link').trigger('click')

    expect(wrapper.find('.ct-download-commercial').exists()).toBe(true)
    expect(store.downloadItems).toEqual([])
  })

  it('adds a download item immediately for a non-commercial option', async () => {
    const store = useDownloads()
    const nonCommercial = { ...csvOption, commercialAvailable: false }
    const wrapper = mountDownload([nonCommercial])

    await wrapper.find('.ct-download__trigger').trigger('click')
    await wrapper.find('.ct-download-popup__link').trigger('click')

    expect(store.downloadItems).toHaveLength(1)
    expect(store.downloadItems[0]).toMatchObject({ domain: 'protected_area', format: 'csv', token: 'abc' })
  })

  it('adds the item once the commercial modal is dismissed non-commercially', async () => {
    const store = useDownloads()
    const wrapper = mountDownload()

    await wrapper.find('.ct-download__trigger').trigger('click')
    await wrapper.find('.ct-download-popup__link').trigger('click')
    await wrapper.find('.ct-download-commercial__link-button').trigger('click')

    expect(store.downloadItems).toHaveLength(1)
    expect(wrapper.find('.ct-download-commercial').exists()).toBe(false)
  })

  it('attaches the store\'s search filters/term for a "search" domain option', async () => {
    const store = useDownloads()
    store.updateSearchFilters([{ key: 'iucn_category', value: 'Ia' }])
    store.updateSearchTerm('coral reef')
    const wrapper = mountDownload([searchOption])

    await wrapper.find('.ct-download__trigger').trigger('click')
    await wrapper.find('.ct-download-popup__link').trigger('click')
    await wrapper.find('.ct-download-commercial__link-button').trigger('click')

    expect(store.downloadItems[0]).toMatchObject({
      filters: [{ key: 'iucn_category', value: 'Ia' }],
      search: 'coral reef'
    })
  })
})
