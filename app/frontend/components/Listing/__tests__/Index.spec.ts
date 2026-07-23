import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import Listing from '@/components/Listing/Index.vue'
import ListingList from '@/components/Listing/List.vue'

class FakeIntersectionObserver {
  observe = vi.fn()
  disconnect = vi.fn()
  unobserve = vi.fn()
}

function jsonResponse(data: unknown) {
  return { ok: true, status: 200, json: () => Promise.resolve(data) } as Response
}

function meta() {
  const tag = document.createElement('meta')
  tag.name = 'csrf-token'
  tag.content = 'test-token'
  document.head.appendChild(tag)
}

async function flushPromises() {
  for (let i = 0; i < 4; i++) {
    await Promise.resolve()
  }
}

const baseProps = {
  endpointSearch: '/en/search-cms',
  filterGroups: [
    {
      title: 'Filter by',
      filters: [
        {
          id: 'topics',
          title: 'Topics',
          type: 'checkbox' as const,
          options: [{ id: 'wdpa', title: 'WDPA' }]
        }
      ]
    }
  ],
  gaId: 'Slug: news',
  pageId: 5,
  results: {
    total: 1,
    totalPages: 1,
    results: [{ title: 'First', url: 'first', summary: 'One' }]
  },
  template: 'news' as const,
  textClear: 'Clear',
  textFiltersClose: 'View Results',
  textFilterTrigger: 'Filters',
  textNoResults: 'No Results'
}

beforeEach(() => {
  vi.stubGlobal('IntersectionObserver', FakeIntersectionObserver)
  vi.stubGlobal('fetch', vi.fn())
  meta()
  window.history.replaceState({}, '', '/en/news')
})

afterEach(() => {
  document.head.innerHTML = ''
  vi.unstubAllGlobals()
})

describe('Listing Index', () => {
  it('renders the initial server-provided results with no fetch', () => {
    const wrapper = mount(Listing, { props: baseProps })

    expect(wrapper.find('.card__h3').text()).toBe('First')
    expect(fetch).not.toHaveBeenCalled()
  })

  it('toggles the filter pane on trigger click', async () => {
    const wrapper = mount(Listing, { props: baseProps })

    expect(wrapper.find('.filters--sidebar').attributes('style')).toContain('display: none')

    await wrapper.find('.listing__filters-trigger').trigger('click')

    expect(wrapper.find('.filters--sidebar').attributes('style')).not.toContain('display: none')
  })

  it('requests search results with the selected filters and syncs the URL', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({
      total: 1,
      totalPages: 1,
      results: [{ title: 'Filtered', url: 'filtered', summary: 'Result' }]
    }))

    const wrapper = mount(Listing, { props: baseProps })

    await wrapper.find('input[value="wdpa"]').setValue(true)
    await flushPromises()
    await wrapper.vm.$nextTick()

    const [url, options] = vi.mocked(fetch).mock.calls[0]
    expect(String(url)).toContain('/en/search-cms?')
    const query = new URL(String(url), 'http://localhost').searchParams
    expect(query.getAll('filters[topics][]')).toEqual(['wdpa'])
    expect(query.get('filters[ancestor]')).toBe('5')
    expect(query.get('items_per_page')).toBe('6')
    expect(query.get('requested_page')).toBe('1')
    expect(query.get('search_index')).toBe('cms')
    expect((options as RequestInit).headers).toMatchObject({ 'X-CSRF-Token': 'test-token' })

    expect(wrapper.find('.card__h3').text()).toBe('Filtered')
    expect(window.location.search).toContain('filters%5Btopics%5D%5B%5D=wdpa')
  })

  it('requests more results on pagination and appends them to the existing list', async () => {
    const props = {
      ...baseProps,
      results: {
        total: 2,
        totalPages: 2,
        results: [{ title: 'First', url: 'first', summary: 'One' }]
      }
    }
    vi.mocked(fetch).mockResolvedValue(jsonResponse({
      total: 2,
      totalPages: 2,
      results: [{ title: 'Second', url: 'second', summary: 'Two' }]
    }))

    const wrapper = mount(Listing, { props })

    await wrapper.findComponent(ListingList).vm.$emit('requestMore', 2)
    await flushPromises()
    await wrapper.vm.$nextTick()

    const [url] = vi.mocked(fetch).mock.calls[0]
    const query = new URL(String(url), 'http://localhost').searchParams
    expect(query.get('requested_page')).toBe('2')

    const titles = wrapper.findAll('.card__h3').map(el => el.text())
    expect(titles).toEqual(['First', 'Second'])
  })
})
