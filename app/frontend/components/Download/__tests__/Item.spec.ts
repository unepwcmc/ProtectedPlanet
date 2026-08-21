import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import DownloadItem from '@/components/Download/Item.vue'
import { useDownloads, resetDownloads, POLL_TIMEOUT_MS, type DownloadItemParams } from '@/composables/useDownloads'

const text = { download: 'Download', failed: 'Failed', generating: 'Generating...' }
const request = { domain: 'protected_area', format: 'csv', token: 'abc' }

function jsonResponse(data: unknown) {
  return { ok: true, status: 200, json: () => Promise.resolve(data) } as Response
}

function meta() {
  const tag = document.createElement('meta')
  tag.name = 'csrf-token'
  tag.content = 'test-token'
  document.head.appendChild(tag)
}

// Items only ever exist as children of the modal's v-for over the store, so the
// specs set them up the same way.
function mountItem(params: DownloadItemParams) {
  return mount(DownloadItem, {
    props: { endpointCreate: '/downloads', endpointPoll: '/downloads/poll', gaId: 'test', params, text }
  })
}

// A download this page load requested by click: the store hands out one create.
function mountRequested(store: ReturnType<typeof useDownloads>) {
  return mountItem(store.addNewDownloadItem(request))
}

// A download that arrived from another tab or survived a reload: no create.
function mountRestored(store: ReturnType<typeof useDownloads>, params: Partial<DownloadItemParams> = {}) {
  const item = store.addNewDownloadItem({ ...request, ...params })
  if (Object.keys(params).length > 0) store.patchDownloadItem(item.id, params)
  store.consumeCreateRequest(item.id)

  return mountItem(store.downloadItems[0])
}

const requests = () => vi.mocked(fetch).mock.calls.map(([url, init]) => `${(init as RequestInit)?.method ?? 'GET'} ${url}`)

beforeEach(() => {
  localStorage.clear()
  sessionStorage.clear()
  resetDownloads()
  vi.stubGlobal('fetch', vi.fn())
  meta()
})

afterEach(() => {
  document.head.innerHTML = ''
  vi.useRealTimers()
  vi.unstubAllGlobals()
})

describe('DownloadItem', () => {
  it('asks the server to generate the file for the click that requested it, and shows the generating state', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ hasFailed: false, title: 'PA.csv', url: '' }))
    const store = useDownloads()

    const wrapper = mountRequested(store)
    await flushPromises()
    await wrapper.vm.$nextTick()

    expect(fetch).toHaveBeenCalledWith('/downloads', expect.objectContaining({
      method: 'POST',
      headers: expect.objectContaining({ 'X-CSRF-Token': 'test-token' }),
      body: JSON.stringify(request)
    }))
    expect(requests()).toHaveLength(1)
    expect(wrapper.find('.ct-download-item__title').text()).toBe('PA.csv')
    expect(wrapper.find('.ct-download-item__status--generating').isVisible()).toBe(true)
    expect(wrapper.find('.ct-download-item__link').exists()).toBe(false)
  })

  it('only ever polls for a download it did not request itself', async () => {
    vi.useFakeTimers()
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ hasFailed: false, title: 'PA.csv', url: '' }))
    const store = useDownloads()

    mountRestored(store)
    await vi.advanceTimersByTimeAsync(30000)

    expect(requests().some(request => request.startsWith('POST'))).toBe(false)
    expect(requests()[0]).toBe('GET /downloads/poll?domain=protected_area&format=csv&token=abc')
  })

  it('polls straight away rather than waiting out an interval first', async () => {
    vi.useFakeTimers()
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ hasFailed: false, title: 'PA.csv', url: '/files/pa.csv' }))
    const store = useDownloads()

    const wrapper = mountRestored(store)
    await vi.advanceTimersByTimeAsync(0)
    await wrapper.vm.$nextTick()

    expect(requests()).toHaveLength(1)
    expect(wrapper.find('.ct-download-item__link').attributes('href')).toBe('/files/pa.csv')
  })

  it('shows the ready download link once a url arrives, and stops polling', async () => {
    vi.useFakeTimers()
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ hasFailed: false, title: 'PA.csv', url: '/files/pa.csv' }))
    const store = useDownloads()

    const wrapper = mountRequested(store)
    await vi.advanceTimersByTimeAsync(0)
    await wrapper.vm.$nextTick()

    expect(wrapper.find('.ct-download-item__link').attributes('href')).toBe('/files/pa.csv')

    const before = requests().length
    await vi.advanceTimersByTimeAsync(60000)
    expect(requests()).toHaveLength(before)
  })

  it('keeps the digest a "search" download is polled by, and waits for it before polling', async () => {
    vi.useFakeTimers()
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ hasFailed: false, title: 'search.csv', url: '', token: 'digest' }))
    const store = useDownloads()

    // Another tab's 'search' download, before its create response has landed.
    const item = store.addNewDownloadItem({ domain: 'search', format: 'csv', token: 'all' })
    store.consumeCreateRequest(item.id)
    mountItem(store.downloadItems[0])
    await vi.advanceTimersByTimeAsync(30000)

    expect(requests()).toHaveLength(0)

    store.patchDownloadItem(item.id, { backEndToken: 'digest' })
    await vi.advanceTimersByTimeAsync(15000)

    expect(requests()[0]).toBe('GET /downloads/poll?domain=search&format=csv&token=all&backEndToken=digest')
  })

  it('records the digest from its own create response, so the next page load can poll', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ hasFailed: false, title: 'search.csv', url: '', token: 'digest' }))
    const store = useDownloads()

    const wrapper = mountItem(store.addNewDownloadItem({ domain: 'search', format: 'csv', token: 'all' }))
    await flushPromises()
    await wrapper.vm.$nextTick()

    expect(store.downloadItems[0].backEndToken).toBe('digest')
  })

  it('stores no digest for a domain that is polled by its own token', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ hasFailed: false, title: 'PA.csv', url: '', token: 'abc' }))
    const store = useDownloads()

    const wrapper = mountRequested(store)
    await flushPromises()
    await wrapper.vm.$nextTick()

    expect(store.downloadItems[0].backEndToken).toBeUndefined()
  })

  it('shows the failed state and stops polling when a request errors', async () => {
    vi.useFakeTimers()
    vi.mocked(fetch).mockRejectedValue(new Error('boom'))
    const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
    const store = useDownloads()

    const wrapper = mountRequested(store)
    await vi.advanceTimersByTimeAsync(0)
    await wrapper.vm.$nextTick()

    expect(wrapper.find('.ct-download-item__status--failed').isVisible()).toBe(true)

    const before = requests().length
    await vi.advanceTimersByTimeAsync(60000)
    expect(requests()).toHaveLength(before)

    errorSpy.mockRestore()
  })

  it('gives up rather than polling a download forever', async () => {
    vi.useFakeTimers()
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ hasFailed: false, title: 'PA.csv', url: '' }))
    const store = useDownloads()
    const item = store.addNewDownloadItem(request)
    store.consumeCreateRequest(item.id)
    store.patchDownloadItem(item.id, { createdAt: Date.now() - POLL_TIMEOUT_MS - 1 })

    const wrapper = mountItem(store.downloadItems[0])
    await vi.advanceTimersByTimeAsync(0)
    await wrapper.vm.$nextTick()

    expect(requests()).toHaveLength(0)
    expect(wrapper.find('.ct-download-item__status--failed').isVisible()).toBe(true)
  })

  it('deletes itself from the download store when the delete icon is clicked', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ hasFailed: false, title: 'PA.csv', url: '/files/pa.csv' }))
    const store = useDownloads()

    const wrapper = mountRequested(store)
    await flushPromises()
    await wrapper.vm.$nextTick()

    await wrapper.find('.ct-download-item__delete').trigger('click')

    expect(store.downloadItems).toEqual([])
  })
})

async function flushPromises() {
  for (let i = 0; i < 4; i++) {
    await Promise.resolve()
  }
}
