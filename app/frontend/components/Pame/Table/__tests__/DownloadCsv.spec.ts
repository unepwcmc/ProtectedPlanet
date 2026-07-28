import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import DownloadCsv from '@/components/Pame/Table/DownloadCsv.vue'
import { usePameStore } from '@/stores/usePameStore'

function csrfMeta() {
  const tag = document.createElement('meta')
  tag.name = 'csrf-token'
  tag.content = 'test-token'
  document.head.appendChild(tag)
}

beforeEach(() => {
  setActivePinia(createPinia())
  csrfMeta()
  vi.stubGlobal('fetch', vi.fn())
  vi.stubGlobal('URL', { createObjectURL: vi.fn(() => 'blob:mock'), revokeObjectURL: vi.fn() })
})

describe('Pame Table DownloadCsv', () => {
  it('is disabled when there are no results', () => {
    const wrapper = mount(DownloadCsv, { props: { totalItems: 0 } })

    expect(wrapper.find('button').attributes('disabled')).toBeDefined()
  })

  it('is disabled while another PAME request (e.g. the table fetch) is in flight', () => {
    usePameStore().setFetching(true)
    const wrapper = mount(DownloadCsv, { props: { totalItems: 5 } })

    expect(wrapper.find('button').attributes('disabled')).toBeDefined()
  })

  it('sets the shared fetching flag for the duration of its own download', async () => {
    ;(fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      headers: new Headers(),
      blob: () => Promise.resolve(new Blob(['csv']))
    })

    const store = usePameStore()
    const wrapper = mount(DownloadCsv, { props: { totalItems: 5 } })
    const clickPromise = wrapper.find('button').trigger('click')

    expect(store.isFetching).toBe(true)

    await clickPromise
    await flushPromises()

    expect(store.isFetching).toBe(false)
  })

  it('posts the current filters and triggers a download with the response filename', async () => {
    usePameStore().setFilterOptions([{ name: 'method', options: ['Site visit'] }])

    ;(fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      headers: new Headers({ 'content-disposition': 'attachment; filename="pame.csv"' }),
      blob: () => Promise.resolve(new Blob(['csv']))
    })

    const createElementSpy = vi.spyOn(document, 'createElement')

    const wrapper = mount(DownloadCsv, { props: { totalItems: 5 } })
    await wrapper.find('button').trigger('click')
    await flushPromises()

    const [url, options] = (fetch as ReturnType<typeof vi.fn>).mock.calls[0]
    expect(url).toBe('/pame/download')
    expect(JSON.parse(options.body)).toEqual({ filters: [{ name: 'method', options: ['Site visit'] }] })

    const anchor = createElementSpy.mock.results.find(r => r.value?.tagName === 'A')?.value as HTMLAnchorElement
    expect(anchor?.download).toBe('pame.csv')
  })
})
