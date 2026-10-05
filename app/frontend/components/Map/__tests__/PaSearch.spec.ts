import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import MapPaSearch from '@/components/Map/PaSearch.vue'

function jsonResponse(data: unknown) {
  return { ok: true, status: 200, json: () => Promise.resolve(data) } as Response
}

function meta() {
  const tag = document.createElement('meta')
  tag.name = 'csrf-token'
  tag.content = 'test-token'
  document.head.appendChild(tag)
}

const errorMessages = { no_results: 'No results.', invalid_search_string: 'Type a minimum of 3 characters.' }

function mountSearch() {
  return mount(MapPaSearch, {
    props: {
      autocompleteErrorMessages: errorMessages,
      autocompletePlaceholder: 'Search for a Region, Country or Area',
      type: 'wdpca'
    }
  })
}

beforeEach(() => {
  vi.stubGlobal('fetch', vi.fn())
  meta()
})

afterEach(() => {
  document.head.innerHTML = ''
})

describe('MapPaSearch', () => {
  it('shows the too-short error before three characters are typed', async () => {
    const wrapper = mountSearch()

    await wrapper.find('.ct-map-pa-search__input').setValue('ab')

    expect(wrapper.find('.ct-map-pa-search__result--no-pointer').text()).toBe(errorMessages.invalid_search_string)
    expect(fetch).not.toHaveBeenCalled()
  })

  it('fetches results from /search/autocomplete once three characters are typed', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse([
      { id: 1, is_pa: true, site_pid: '1_A', title: 'Yosemite', url: '/1', extent_url: { url: '/extent/1' } }
    ]))
    const wrapper = mountSearch()

    await wrapper.find('.ct-map-pa-search__input').setValue('yos')
    await vi.waitFor(() => expect(fetch).toHaveBeenCalledTimes(1))

    const [url, init] = vi.mocked(fetch).mock.calls[0]
    expect(url).toBe('/search/autocomplete')
    expect(JSON.parse((init as RequestInit).body as string)).toEqual({
      search_term: 'yos',
      type: 'wdpca',
      index: 'areas'
    })
    await vi.waitFor(() => expect(wrapper.find('.ct-map-pa-search__result').text()).toBe('Yosemite'))
  })

  it('shows the no-results error when the search resolves empty', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse([]))
    const wrapper = mountSearch()

    await wrapper.find('.ct-map-pa-search__input').setValue('xyz')
    await vi.waitFor(() => expect(wrapper.find('.ct-map-pa-search__result--no-pointer').text()).toBe(errorMessages.no_results))
  })

  it('emits zoomTo with the result shaped as ZoomToOptions when a result is clicked', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse([
      { id: 1, is_pa: true, site_pid: '1_A', title: 'Yosemite', url: '/1', extent_url: { url: '/extent/1' } }
    ]))
    const wrapper = mountSearch()

    await wrapper.find('.ct-map-pa-search__input').setValue('yos')
    await vi.waitFor(() => expect(wrapper.find('.ct-map-pa-search__button').exists()).toBe(true))
    await wrapper.find('.ct-map-pa-search__button').trigger('click')

    expect(wrapper.emitted('zoomTo')?.[0]?.[0]).toEqual({
      id: 1,
      is_pa: true,
      site_pid: '1_A',
      title: 'Yosemite',
      url: '/1',
      extent_url: { url: '/extent/1' },
      name: 'Yosemite',
      addPopup: true
    })
  })

  it('clears the search on delete click', async () => {
    const wrapper = mountSearch()

    await wrapper.find('.ct-map-pa-search__input').setValue('yos')
    await wrapper.find('.ct-map-pa-search__delete').trigger('click')

    expect((wrapper.find('.ct-map-pa-search__input').element as HTMLInputElement).value).toBe('')
  })
})
