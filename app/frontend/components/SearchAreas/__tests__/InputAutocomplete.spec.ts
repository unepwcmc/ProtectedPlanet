import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchAreasInputAutocomplete from '@/components/SearchAreas/InputAutocomplete.vue'

function jsonResponse(data: unknown) {
  return { ok: true, status: 200, json: () => Promise.resolve(data) } as Response
}

function meta() {
  const tag = document.createElement('meta')
  tag.name = 'csrf-token'
  tag.content = 'test-token'
  document.head.appendChild(tag)
}

function mountAutocomplete() {
  return mount(SearchAreasInputAutocomplete, {
    props: {
      config: { id: 'all', placeholder: 'Search protected areas' },
      endpoint: '/search/autocomplete'
    },
    attachTo: document.body
  })
}

beforeEach(() => {
  vi.stubGlobal('fetch', vi.fn())
  meta()
})

afterEach(() => {
  document.head.innerHTML = ''
})

describe('SearchAreasInputAutocomplete', () => {
  it('fetches autocomplete results once the user types, keyed on the config id', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse([{ id: 1, title: 'Yosemite', url: '/1' }]))
    const wrapper = mountAutocomplete()

    await wrapper.find('input').setValue('yos')
    await wrapper.find('input').trigger('keyup', { key: 'y' })
    await vi.waitFor(() => expect(fetch).toHaveBeenCalledTimes(1))

    const [url, init] = vi.mocked(fetch).mock.calls[0]
    expect(url).toBe('/search/autocomplete')
    expect(JSON.parse((init as RequestInit).body as string)).toEqual({ search_term: 'yos', type: 'all' })
    await vi.waitFor(() => expect(wrapper.find('.search__a').text()).toBe('Yosemite'))
  })

  it('resets the dropdown and does not fetch on Enter', async () => {
    const wrapper = mountAutocomplete()

    await wrapper.find('input').setValue('yos')
    await wrapper.find('input').trigger('keyup', { key: 'Enter' })

    expect(fetch).not.toHaveBeenCalled()
  })

  it('emits submit:search with the current search term', async () => {
    const wrapper = mountAutocomplete()

    await wrapper.find('input').setValue('yosemite')
    await wrapper.find('input').trigger('keyup.enter')

    expect(wrapper.emitted('submit:search')?.[0]).toEqual(['yosemite'])
  })

  it('clears the search term on delete click', async () => {
    const wrapper = mountAutocomplete()

    await wrapper.find('input').setValue('yosemite')
    await wrapper.find('.search__search-icon--delete').trigger('click')

    expect((wrapper.find('input').element as HTMLInputElement).value).toBe('')
  })

  it('closes the dropdown when clicking outside', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse([{ id: 1, title: 'Yosemite', url: '/1' }]))
    const wrapper = mountAutocomplete()

    await wrapper.find('input').setValue('yos')
    await wrapper.find('input').trigger('keyup', { key: 'y' })
    await vi.waitFor(() => expect(wrapper.find('.search__li').exists()).toBe(true))

    document.body.click()
    await wrapper.vm.$nextTick()

    expect(wrapper.find('.search__li').exists()).toBe(false)
    wrapper.unmount()
  })
})
