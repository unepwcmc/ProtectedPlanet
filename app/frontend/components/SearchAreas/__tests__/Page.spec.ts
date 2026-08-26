import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchAreasPage from '@/components/SearchAreas/Page.vue'
import { useDownloads, resetDownloads } from '@/composables/useDownloads'
import type { SearchAreasPageProps } from '@/types/backend'

function jsonResponse(data: unknown) {
  return { ok: true, status: 200, json: () => Promise.resolve(data) } as Response
}

function meta() {
  const tag = document.createElement('meta')
  tag.name = 'csrf-token'
  tag.content = 'test-token'
  document.head.appendChild(tag)
}

const baseProps: SearchAreasPageProps = {
  configAutocomplete: { id: 'all', placeholder: 'Search protected areas' },
  downloadButtonText: 'Download',
  downloadOptions: [{ isDownload: true, title: 'CSV', commercialAvailable: false, params: { domain: 'search', format: 'csv', token: 'abc' } }],
  downloadTextCommercial: {
    commercialText: '', commercialTitle: '', nonCommercialText: '', nonCommercialTitle: '', nonCommercialButton: '', title: ''
  },
  endpointAutocomplete: '/search/autocomplete',
  endpointSearch: '/search-areas-results',
  filterGroups: [{
    title: 'Filter by',
    filters: [{ id: 'db_type', name: 'db_type', type: 'checkbox', options: [{ id: 'wdpa', title: 'WDPA' }, { id: 'oecm', title: 'OECM' }] }]
  }],
  gaId: 'Component: search areas',
  noResultsText: 'No results.',
  results: { geoType: 'site', title: 'Protected areas', total: 1, totalPages: 1, areas: [{ title: 'Yosemite', url: '/1', image: '/img.jpg' }] },
  smTriggerElement: 'sm-trigger-infinite-scroll',
  tabs: [{ id: 'region', title: 'Region' }, { id: 'country', title: 'Country' }, { id: 'site', title: 'Site' }],
  textClear: 'Clear',
  textClose: 'View Results',
  textFilters: 'Filters'
}

function mountSearchAreas(props: Partial<SearchAreasPageProps> = {}) {
  return mount(SearchAreasPage, { props: { ...baseProps, ...props } })
}

class FakeIntersectionObserver {
  observe = vi.fn()
  disconnect = vi.fn()
  unobserve = vi.fn()
}

beforeEach(() => {
  localStorage.clear()
  resetDownloads()
  vi.stubGlobal('fetch', vi.fn())
  vi.stubGlobal('IntersectionObserver', FakeIntersectionObserver)
  meta()
  window.history.replaceState({}, '', '/search-areas')
})

afterEach(() => {
  document.head.innerHTML = ''
  vi.unstubAllGlobals()
})

describe('SearchAreasPage', () => {
  it('renders the initial results passed in as props', () => {
    const wrapper = mountSearchAreas()

    expect(wrapper.text()).toContain('Yosemite')
  })

  it('shows the no-results message when total is zero', () => {
    const wrapper = mountSearchAreas({ results: { ...baseProps.results, total: 0, areas: [] } })

    expect(wrapper.find('.ct-search-areas-results__none').text()).toBe('No results.')
  })

  it('disables the download button when there are no results', () => {
    const wrapper = mountSearchAreas({ results: { ...baseProps.results, total: 0, areas: [] } })

    expect(wrapper.find('.ct-download__trigger').attributes('disabled')).toBeDefined()
  })

  it('re-fetches results and resets pagination when switching tabs', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({
      areas: { geoType: 'country', title: 'Countries', total: 2, totalPages: 1, areas: [] },
      filters: baseProps.filterGroups
    }))
    const wrapper = mountSearchAreas()

    await wrapper.findAll('.ct-tab-strip [role="tab"]')[1].trigger('click')
    await vi.waitFor(() => expect(fetch).toHaveBeenCalled())

    const [url] = vi.mocked(fetch).mock.calls.at(-1)!
    expect(String(url)).toContain('/search-areas-results')
    expect(String(url)).toContain('geo_type=country')
    expect(window.location.search).toContain('geo_type=country')
  })

  it('disables filters and shows the download for non-site tabs correctly', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({
      areas: { geoType: 'region', title: 'Regions', total: 0, totalPages: 0, areas: [] },
      filters: baseProps.filterGroups
    }))
    const wrapper = mountSearchAreas()

    await wrapper.findAll('.ct-tab-strip [role="tab"]')[0].trigger('click')
    await vi.waitFor(() => expect(fetch).toHaveBeenCalled())

    expect(wrapper.find('.ct-filters-trigger').classes()).toContain('ct-filters-trigger--disabled')
  })

  it('submits a new search term, resets filters, and writes it to the shared download store', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({
      areas: { geoType: 'site', title: 'Protected areas', total: 1, totalPages: 1, areas: [] },
      filters: baseProps.filterGroups
    }))
    const wrapper = mountSearchAreas()
    const downloads = useDownloads()

    await wrapper.find('.ct-search-areas-autocomplete__input').setValue('yosemite')
    await wrapper.find('.ct-search-areas-autocomplete__input').trigger('keyup.enter')
    await vi.waitFor(() => expect(fetch).toHaveBeenCalled())

    expect(downloads.searchTerm).toBe('yosemite')
    expect(window.location.search).toContain('search_term=yosemite')
  })

  it('writes active filters to the shared download store when a filter changes', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({
      areas: { geoType: 'site', title: 'Protected areas', total: 1, totalPages: 1, areas: [] },
      filters: baseProps.filterGroups
    }))
    const wrapper = mountSearchAreas()
    const downloads = useDownloads()

    await wrapper.find('.ct-filters-trigger').trigger('click')
    await wrapper.find('input[value="wdpa"]').setValue(true)
    await vi.waitFor(() => expect(fetch).toHaveBeenCalled())

    expect(downloads.searchFilters).toEqual({ db_type: ['wdpa'] })
  })

  it('does not re-fetch when opening the filters panel on a URL-preselected filter', async () => {
    window.history.replaceState({}, '', '/search-areas?filters%5Bdb_type%5D%5B%5D=wdpa')
    const wrapper = mountSearchAreas()
    const downloads = useDownloads()

    expect(downloads.searchFilters).toEqual({ db_type: ['wdpa'] })

    await wrapper.find('.ct-filters-trigger').trigger('click')
    await new Promise(resolve => setTimeout(resolve, 0))

    expect(wrapper.find('input[value="wdpa"]').element).toHaveProperty('checked', true)
    expect(fetch).not.toHaveBeenCalled()
  })

  it('clears active filters when switching tabs', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({
      areas: { geoType: 'site', title: 'Protected areas', total: 1, totalPages: 1, areas: [] },
      filters: baseProps.filterGroups
    }))
    const wrapper = mountSearchAreas()
    const downloads = useDownloads()

    await wrapper.find('.ct-filters-trigger').trigger('click')
    await wrapper.find('input[value="wdpa"]').setValue(true)
    await vi.waitFor(() => expect(window.location.search).toContain('filters%5Bdb_type%5D%5B%5D=wdpa'))

    await wrapper.findAll('.ct-tab-strip [role="tab"]')[1].trigger('click')
    await vi.waitFor(() => expect(window.location.search).toContain('geo_type=country'))

    const [url] = vi.mocked(fetch).mock.calls.at(-1)!
    expect(String(url)).toContain(`filters=${encodeURIComponent('{}')}`)
    expect(window.location.search).not.toContain('db_type')
    expect(downloads.searchFilters).toEqual({})
    // One request for the tab switch, not a second from the filter groups
    // re-emitting their cleared selection.
    expect(fetch).toHaveBeenCalledTimes(2)
  })

  it('hides the previous results and shows the spinner while re-fetching', async () => {
    let resolveFetch: (value: Response) => void = () => {}
    vi.mocked(fetch).mockReturnValue(new Promise<Response>((resolve) => {
      resolveFetch = resolve
    }))
    const wrapper = mountSearchAreas()

    expect(wrapper.text()).toContain('Yosemite')

    await wrapper.findAll('.ct-tab-strip [role="tab"]')[1].trigger('click')
    await vi.waitFor(() => expect(wrapper.find('.ct-search-areas-page__spinner').exists()).toBe(true))

    expect(wrapper.find('.ct-search-areas-results').attributes('style')).toContain('display: none')

    resolveFetch(jsonResponse({
      areas: { geoType: 'country', title: 'Countries', total: 1, totalPages: 1, areas: [{ title: 'Kenya', url: '/ke', image: '/ke.jpg' }] },
      filters: baseProps.filterGroups
    }))
    await vi.waitFor(() => expect(wrapper.find('.ct-search-areas-results').attributes('style') ?? '').not.toContain('display: none'))

    expect(wrapper.find('.ct-search-areas-page__spinner').exists()).toBe(false)
    expect(wrapper.text()).toContain('Kenya')
  })

  it('requests the next page and appends results on infinite scroll', async () => {
    class FakeIntersectionObserver {
      callback: IntersectionObserverCallback
      constructor(callback: IntersectionObserverCallback) { this.callback = callback }
      observe() { this.callback([{ isIntersecting: true } as IntersectionObserverEntry], this as unknown as IntersectionObserver) }
      disconnect() {}
    }
    vi.stubGlobal('IntersectionObserver', FakeIntersectionObserver)
    vi.mocked(fetch).mockResolvedValue(jsonResponse({
      areas: { geoType: 'site', title: 'Protected areas', total: 2, totalPages: 2, areas: [{ title: 'Denali', url: '/2', image: '/img2.jpg' }] },
      filters: baseProps.filterGroups
    }))

    const wrapper = mountSearchAreas({ results: { ...baseProps.results, totalPages: 2 } })
    await vi.waitFor(() => expect(fetch).toHaveBeenCalled())
    await vi.waitFor(() => expect(wrapper.text()).toContain('Denali'))

    expect(wrapper.text()).toContain('Yosemite')
  })
})
