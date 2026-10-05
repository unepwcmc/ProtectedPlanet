import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import DownloadCsv from '@/components/Pame/Table/DownloadCsv.vue'

function csrfMeta() {
  const tag = document.createElement('meta')
  tag.name = 'csrf-token'
  tag.content = 'test-token'
  document.head.appendChild(tag)
}

beforeEach(() => {
  csrfMeta()
  vi.stubGlobal('fetch', vi.fn())
  vi.stubGlobal('URL', { createObjectURL: vi.fn(() => 'blob:mock'), revokeObjectURL: vi.fn() })
})

describe('Pame Table DownloadCsv', () => {
  it('is disabled when there are no results', () => {
    const wrapper = mount(DownloadCsv, { props: { isFetching: false, selectedFilterOptions: [], totalItems: 0 } })

    expect(wrapper.find('button').attributes('disabled')).toBeDefined()
  })

  it('is disabled while another PAME request (e.g. the table fetch) is in flight', () => {
    const wrapper = mount(DownloadCsv, { props: { isFetching: true, selectedFilterOptions: [], totalItems: 5 } })

    expect(wrapper.find('button').attributes('disabled')).toBeDefined()
  })

  it('emits update:isFetching for the duration of its own download', async () => {
    ;(fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      headers: new Headers(),
      blob: () => Promise.resolve(new Blob(['csv']))
    })

    const wrapper = mount(DownloadCsv, { props: { isFetching: false, selectedFilterOptions: [], totalItems: 5 } })
    const clickPromise = wrapper.find('button').trigger('click')

    expect(wrapper.emitted('update:isFetching')?.[0]).toEqual([true])

    await clickPromise
    await flushPromises()

    expect(wrapper.emitted('update:isFetching')?.[1]).toEqual([false])
  })

  it('posts the filters passed in as a prop and triggers a download with the response filename', async () => {
    ;(fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      headers: new Headers({ 'content-disposition': 'attachment; filename="pame.csv"' }),
      blob: () => Promise.resolve(new Blob(['csv']))
    })

    const createElementSpy = vi.spyOn(document, 'createElement')

    const wrapper = mount(DownloadCsv, {
      props: { isFetching: false, selectedFilterOptions: [{ name: 'method', options: ['Site visit'] }], totalItems: 5 }
    })
    await wrapper.find('button').trigger('click')
    await flushPromises()

    const [url, options] = (fetch as ReturnType<typeof vi.fn>).mock.calls[0]
    expect(url).toBe('/pame/download')
    expect(JSON.parse(options.body)).toEqual({ filters: [{ name: 'method', options: ['Site visit'] }] })

    const anchor = createElementSpy.mock.results.find(r => r.value?.tagName === 'A')?.value as HTMLAnchorElement
    expect(anchor?.download).toBe('pame.csv')
  })
})
