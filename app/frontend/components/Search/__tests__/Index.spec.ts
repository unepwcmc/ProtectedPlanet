import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchSite from '@/components/Search/Index.vue'
import type { SearchSiteProps } from '@/types/backend'

function jsonResponse(data: unknown) {
  return { ok: true, status: 200, json: () => Promise.resolve(data) } as Response
}

function meta() {
  const tag = document.createElement('meta')
  tag.name = 'csrf-token'
  tag.content = 'test-token'
  document.head.appendChild(tag)
}

const baseProps: SearchSiteProps = {
  categories: [{ id: 'all', title: 'All' }, { id: '12', title: 'News and stories' }, { id: '34', title: 'Resources' }],
  dataPageLoad: {
    searchTerm: '',
    currentPage: 1,
    pageItemsStart: 1,
    pageItemsEnd: 1,
    totalItems: 1,
    results: [{ title: 'Yosemite', url: '/1', summary: 'A park', image: '/img.jpg' }]
  },
  endpoint: '/search-results',
  gaId: 'Component: search site',
  noResultsText: 'No results.',
  placeholder: 'Search',
  resultsText: 'results'
}

function mountSearchSite(props: Partial<SearchSiteProps> = {}) {
  return mount(SearchSite, { props: { ...baseProps, ...props } })
}

beforeEach(() => {
  vi.stubGlobal('fetch', vi.fn())
  meta()
  window.history.replaceState({}, '', '/search')
})

afterEach(() => {
  document.head.innerHTML = ''
  vi.unstubAllGlobals()
})

describe('SearchSite', () => {
  it('renders the initial results passed in as props', () => {
    const wrapper = mountSearchSite()

    expect(wrapper.text()).toContain('Yosemite')
    expect(wrapper.find('.ct-search-results__total').text()).toBe('(1 results)')
  })

  it('pre-populates the search term from the URL query string', () => {
    window.history.replaceState({}, '', '/search?search_term=marine')

    const wrapper = mountSearchSite()

    expect((wrapper.find('.ct-search__input').element as HTMLInputElement).value).toBe('marine')
  })

  it('re-fetches results scoped to the selected category tab', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({
      searchTerm: '', currentPage: 1, pageItemsStart: 1, pageItemsEnd: 1, totalItems: 0, results: []
    }))
    const wrapper = mountSearchSite()

    await wrapper.findAll('.ct-tab-strip [role="tab"]')[1].trigger('click')
    await vi.waitFor(() => expect(fetch).toHaveBeenCalled())

    const [url] = vi.mocked(fetch).mock.calls.at(-1)!
    expect(String(url)).toContain('/search-results')
    expect(String(url)).toContain(encodeURIComponent('{"ancestor":"12"}'))
  })

  it('submits a new search term, resets the category tab, and syncs the URL', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({
      searchTerm: 'coral', currentPage: 1, pageItemsStart: 1, pageItemsEnd: 1, totalItems: 0, results: []
    }))
    const wrapper = mountSearchSite()

    await wrapper.findAll('.ct-tab-strip [role="tab"]')[1].trigger('click')
    await vi.waitFor(() => expect(fetch).toHaveBeenCalledTimes(1))
    await vi.waitFor(() => expect(wrapper.find('.ct-search__input').attributes('disabled')).toBeUndefined())

    await wrapper.find('.ct-search__input').setValue('coral')
    await wrapper.find('.ct-search__input').trigger('keyup.enter')
    await vi.waitFor(() => expect(fetch).toHaveBeenCalledTimes(2))

    expect(window.location.search).toContain('search_term=coral')
    expect(wrapper.findAll('.ct-tab-strip [role="tab"]')[0].classes()).toContain('ct-tab-strip-tab--active')
  })

  it('disables the input, tabs, and pagination while a request is in flight', async () => {
    let resolveFetch: (value: Response) => void = () => {}
    vi.mocked(fetch).mockReturnValue(new Promise((resolve) => {
      resolveFetch = resolve
    }))
    const wrapper = mountSearchSite({ dataPageLoad: { ...baseProps.dataPageLoad, pageItemsEnd: 1, totalItems: 3 } })

    await wrapper.find('.ct-search-pagination__button--next').trigger('click')

    expect(wrapper.find('.ct-search__input').attributes('disabled')).toBeDefined()
    expect(wrapper.findAll('.ct-tab-strip [role="tab"]')[1].attributes('aria-disabled')).toBe('true')
    expect(wrapper.find('.ct-search-pagination__button--next').attributes('disabled')).toBeDefined()

    resolveFetch(jsonResponse({
      searchTerm: '', currentPage: 2, pageItemsStart: 2, pageItemsEnd: 2, totalItems: 3, results: []
    }))
    await vi.waitFor(() => expect(wrapper.find('.ct-search__input').attributes('disabled')).toBeUndefined())
  })

  it('requests the next page via the pagination controls', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({
      searchTerm: '', currentPage: 2, pageItemsStart: 2, pageItemsEnd: 2, totalItems: 3, results: []
    }))
    const wrapper = mountSearchSite({ dataPageLoad: { ...baseProps.dataPageLoad, pageItemsEnd: 1, totalItems: 3 } })

    await wrapper.find('.ct-search-pagination__button--next').trigger('click')
    await vi.waitFor(() => expect(fetch).toHaveBeenCalled())

    const [url] = vi.mocked(fetch).mock.calls.at(-1)!
    expect(String(url)).toContain('requested_page=2')
  })
})
