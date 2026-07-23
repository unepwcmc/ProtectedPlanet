import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import DownloadItem from '@/components/Download/Item.vue'
import { useDownloadStore } from '@/stores/useDownloadStore'

const text = { download: 'Download', failed: 'Failed', generating: 'Generating...' }
const params = { id: 1, domain: 'protected_area', format: 'csv', token: 'abc' }

function jsonResponse(data: unknown) {
  return { ok: true, status: 200, json: () => Promise.resolve(data) } as Response
}

function meta() {
  const tag = document.createElement('meta')
  tag.name = 'csrf-token'
  tag.content = 'test-token'
  document.head.appendChild(tag)
  return tag
}

beforeEach(() => {
  setActivePinia(createPinia())
  vi.stubGlobal('fetch', vi.fn())
  meta()
})

afterEach(() => {
  document.head.innerHTML = ''
  vi.useRealTimers()
  vi.unstubAllGlobals()
})

describe('DownloadItem', () => {
  it('requests the download on mount and shows the generating state until a url arrives', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ hasFailed: false, id: 1, title: 'PA.csv', url: '' }))

    const wrapper = mount(DownloadItem, {
      props: { endpointCreate: '/downloads', endpointPoll: '/downloads/poll', gaId: 'test', params, text }
    })
    await flushPromises()
    await wrapper.vm.$nextTick()

    expect(fetch).toHaveBeenCalledWith('/downloads', expect.objectContaining({
      method: 'POST',
      headers: expect.objectContaining({ 'X-CSRF-Token': 'test-token' }),
      body: JSON.stringify(params)
    }))
    expect(wrapper.find('.modal__li-title').text()).toBe('PA.csv')
    expect(wrapper.find('.modal__li-generating').isVisible()).toBe(true)
    expect(wrapper.find('.modal__li-download').isVisible()).toBe(false)
  })

  it('shows the ready download link once a url is present', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ hasFailed: false, id: 1, title: 'PA.csv', url: '/files/pa.csv' }))

    const wrapper = mount(DownloadItem, {
      props: { endpointCreate: '/downloads', endpointPoll: '/downloads/poll', gaId: 'test', params, text }
    })
    await flushPromises()
    await wrapper.vm.$nextTick()

    expect(wrapper.find('.modal__li-download').isVisible()).toBe(true)
    expect(wrapper.find('.modal__li-download').attributes('href')).toBe('/files/pa.csv')
  })

  it('shows the failed state and stops polling when the create request errors', async () => {
    vi.useFakeTimers()
    vi.mocked(fetch).mockRejectedValue(new Error('boom'))

    const wrapper = mount(DownloadItem, {
      props: { endpointCreate: '/downloads', endpointPoll: '/downloads/poll', gaId: 'test', params, text }
    })
    await flushPromises()
    await wrapper.vm.$nextTick()

    expect(wrapper.find('.modal__li-failed').isVisible()).toBe(true)

    const callsBeforePoll = vi.mocked(fetch).mock.calls.length
    await vi.advanceTimersByTimeAsync(15000)
    expect(vi.mocked(fetch).mock.calls.length).toBe(callsBeforePoll)
  })

  it('deletes itself from the download store when the delete icon is clicked', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ hasFailed: false, id: 1, title: 'PA.csv', url: '/files/pa.csv' }))
    const store = useDownloadStore()
    store.addNewDownloadItem(params)

    const wrapper = mount(DownloadItem, {
      props: { endpointCreate: '/downloads', endpointPoll: '/downloads/poll', gaId: 'test', params, text }
    })
    await flushPromises()
    await wrapper.vm.$nextTick()

    await wrapper.find('.modal__li-delete').trigger('click')

    expect(store.downloadItems).toEqual([])
  })
})

async function flushPromises() {
  for (let i = 0; i < 4; i++) {
    await Promise.resolve()
  }
}
