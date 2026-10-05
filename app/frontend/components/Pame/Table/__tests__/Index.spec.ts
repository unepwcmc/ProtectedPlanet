import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import PameTable from '@/components/Pame/Table/Index.vue'
import type { PameTableProps } from '@/types/backend'

function jsonResponse(data: unknown) {
  return { ok: true, status: 200, json: () => Promise.resolve(data) } as Response
}

const attributes = [
  { title: 'Name', field: 'name' },
  { title: 'Designation', field: 'designation' },
  { title: 'Site/Parcel ID', field: 'site_id', tooltip: 'Unrestricted Protected Areas can be viewed' },
  { title: 'Assessment ID', field: 'asmt_id' },
  { title: 'Country/Territory', field: 'country' },
  { title: 'Method', field: 'method' },
  { title: 'Year of assessment', field: 'asmt_year' },
  { title: 'Link to assessment', field: 'asmt_url' },
  { title: 'Metadata ID', field: 'eff_metaid' }
]

const item = {
  id: 1,
  asmt_id: 'A1',
  site_id: 1,
  site_pid: '1',
  pa_site_url: '/1',
  country: ['Kenya'],
  method: 'Site visit',
  asmt_year: '2020',
  asmt_url: 'https://example.com',
  eff_metaid: 1,
  source_id: 1,
  name: 'Area 1',
  designation: 'National Park',
  data_title: null,
  resp_party: null,
  language: null,
  source_year: null
}

const props: PameTableProps = {
  endpoint: '/pame/list',
  filters: [{ name: 'method', title: 'Method', options: ['Site visit'], type: 'multiple' }],
  attributes,
  json: { current_page: 1, per_page: 50, total_entries: 1, total_pages: 1, items: [item] },
  modalText: {
    modal_title: 'Assessment details',
    id: 'ID',
    title: 'Title',
    responsible: 'Responsible party',
    year: 'Year',
    language: 'Language'
  }
}

beforeEach(() => {
  vi.stubGlobal('fetch', vi.fn())
  window.history.replaceState({}, '', '/data/gdpame')
})

describe('Pame Table Index', () => {
  it('renders the initial items from the json prop without fetching', () => {
    const wrapper = mount(PameTable, { props })

    expect(wrapper.findAll('.ct-pame-table-row-desktop')).toHaveLength(1)
    expect(fetch).not.toHaveBeenCalled()
  })

  it('re-fetches with the requested page and current filters when a filter is applied', async () => {
    const page2 = { current_page: 1, per_page: 50, total_entries: 60, total_pages: 2, items: [{ ...item, id: 2 }] }
    ;(fetch as ReturnType<typeof vi.fn>).mockResolvedValue(jsonResponse(page2))

    const wrapper = mount(PameTable, { props })

    await wrapper.find('.ct-pame-filter__button').trigger('click')
    await wrapper.find('.ct-pame-filter-option__checkbox').setValue(true)
    await wrapper.find('.ct-pame-filter-mobile__button-apply').trigger('click')
    await flushPromises()

    const [, options] = (fetch as ReturnType<typeof vi.fn>).mock.calls[0]
    expect(JSON.parse(options.body)).toEqual({
      requested_page: 1,
      filters: [{ name: 'method', options: ['Site visit'], type: 'multiple' }]
    })
    expect(wrapper.text()).toContain('60')
  })

  it('writes the applied filter to the URL query string — the URL is the only place applied filters live', async () => {
    (fetch as ReturnType<typeof vi.fn>).mockResolvedValue(jsonResponse({ ...props.json, items: [] }))

    const wrapper = mount(PameTable, { props })

    await wrapper.find('.ct-pame-filter__button').trigger('click')
    await wrapper.find('.ct-pame-filter-option__checkbox').setValue(true)
    await wrapper.find('.ct-pame-filter-mobile__button-apply').trigger('click')
    await flushPromises()

    expect(window.location.search).toBe('?pame_filters%5Bmethod%5D%5B%5D=Site+visit')
  })

  it('re-fetches immediately using filters already present in the URL on load, and pre-checks them', async () => {
    window.history.replaceState({}, '', '/data/gdpame?pame_filters%5Bmethod%5D%5B%5D=Site+visit')
    const filtered = { ...props.json, total_entries: 1, items: [item] }
    ;(fetch as ReturnType<typeof vi.fn>).mockResolvedValue(jsonResponse(filtered))

    const wrapper = mount(PameTable, { props })
    await flushPromises()

    const [, options] = (fetch as ReturnType<typeof vi.fn>).mock.calls[0]
    expect(JSON.parse(options.body)).toEqual({
      requested_page: 1,
      filters: [{ name: 'method', options: ['Site visit'], type: 'multiple' }]
    })

    await wrapper.find('.ct-pame-filter__button').trigger('click')
    const checkbox = wrapper.find('.ct-pame-filter-option__checkbox').element as HTMLInputElement
    expect(checkbox.checked).toBe(true)
  })

  it('re-fetches on pagination', async () => {
    const page2 = { current_page: 2, per_page: 50, total_entries: 120, total_pages: 3, items: [{ ...item, id: 3 }] }
    ;(fetch as ReturnType<typeof vi.fn>).mockResolvedValue(jsonResponse(page2))

    const wrapper = mount(PameTable, {
      props: { ...props, json: { ...props.json, total_entries: 120, total_pages: 3 } }
    })

    await wrapper.find('.ct-pame-table-pagination__button--next').trigger('click')
    await flushPromises()

    expect(fetch).toHaveBeenCalledTimes(1)
    expect(wrapper.text()).toContain('51 - 100 of 120')
  })

  it('ignores a second pagination click while the first page request is still in flight', async () => {
    let resolveFetch: (value: Response) => void = () => {}
    ;(fetch as ReturnType<typeof vi.fn>).mockReturnValue(new Promise((resolve) => {
      resolveFetch = resolve
    }))

    const wrapper = mount(PameTable, {
      props: { ...props, json: { ...props.json, total_entries: 120, total_pages: 3 } }
    })

    const nextButton = wrapper.find('.ct-pame-table-pagination__button--next')
    await nextButton.trigger('click')
    // The button disables itself once isFetching flips, but the guard in fetchItems
    // is what actually matters here — assert the network effect, not just the
    // disabled attribute.
    await nextButton.trigger('click')

    expect(fetch).toHaveBeenCalledTimes(1)

    resolveFetch(jsonResponse({ current_page: 2, per_page: 50, total_entries: 120, total_pages: 3, items: [] }))
    await flushPromises()

    expect(fetch).toHaveBeenCalledTimes(1)
  })

  it('shows a loading overlay over the table while a request is in flight, then hides it', async () => {
    let resolveFetch: (value: Response) => void = () => {}
    ;(fetch as ReturnType<typeof vi.fn>).mockReturnValue(new Promise((resolve) => {
      resolveFetch = resolve
    }))

    const wrapper = mount(PameTable, {
      props: { ...props, json: { ...props.json, total_entries: 120, total_pages: 3 } }
    })

    expect(wrapper.find('.ct-pame-table__overlay').exists()).toBe(false)

    await wrapper.find('.ct-pame-table-pagination__button--next').trigger('click')

    expect(wrapper.find('.ct-pame-table__overlay').exists()).toBe(true)
    expect(wrapper.find('.ct-pame-table__body').attributes('aria-busy')).toBe('true')

    resolveFetch(jsonResponse({ current_page: 2, per_page: 50, total_entries: 120, total_pages: 3, items: [] }))
    await flushPromises()

    expect(wrapper.find('.ct-pame-table__overlay').exists()).toBe(false)
    expect(wrapper.find('.ct-pame-table__body').attributes('aria-busy')).toBe('false')
  })

  it('renders the modal alongside the table and opens it from a row click', async () => {
    const wrapper = mount(PameTable, { props })

    expect(wrapper.find('.ct-pame-modal').exists()).toBe(true)
    expect(wrapper.find('.ct-pame-modal').classes()).not.toContain('ct-pame-modal--active')

    await wrapper.find('.ct-pame-table-row-desktop__cell--modal-trigger').trigger('click')

    expect(wrapper.find('.ct-pame-modal').classes()).toContain('ct-pame-modal--active')
    expect(wrapper.text()).toContain('Assessment details')
  })
})
