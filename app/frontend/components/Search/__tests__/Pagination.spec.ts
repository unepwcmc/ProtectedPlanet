import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchPagination from '@/components/Search/Pagination.vue'

const baseProps = { currentPage: 2, noResultsText: 'No results.', pageItemsEnd: 30, pageItemsStart: 16, totalItems: 45 }

describe('SearchPagination', () => {
  it('renders the item range and enables both buttons mid-range', () => {
    const wrapper = mount(SearchPagination, { props: baseProps })

    expect(wrapper.find('.ct-search-pagination').text()).toBe('16 - 30 of 45')
    expect(wrapper.find('.ct-search-pagination__button--previous').attributes('disabled')).toBeUndefined()
    expect(wrapper.find('.ct-search-pagination__button--next').attributes('disabled')).toBeUndefined()
  })

  it('disables previous on the first page and next on the last page', () => {
    const wrapper = mount(SearchPagination, {
      props: { ...baseProps, currentPage: 1, pageItemsStart: 1, pageItemsEnd: 45, totalItems: 45 }
    })

    expect(wrapper.find('.ct-search-pagination__button--previous').attributes('disabled')).toBeDefined()
    expect(wrapper.find('.ct-search-pagination__button--next').attributes('disabled')).toBeDefined()
  })

  it('emits update:page with the next/previous page number', async () => {
    const wrapper = mount(SearchPagination, { props: baseProps })

    await wrapper.find('.ct-search-pagination__button--next').trigger('click')
    await wrapper.find('.ct-search-pagination__button--previous').trigger('click')

    expect(wrapper.emitted('update:page')).toEqual([[3], [1]])
  })

  it('shows the no-results message instead of controls when totalItems is zero', () => {
    const wrapper = mount(SearchPagination, {
      props: { ...baseProps, totalItems: 0, pageItemsStart: 1, pageItemsEnd: 1 }
    })

    expect(wrapper.find('.ct-search-pagination').exists()).toBe(false)
    expect(wrapper.find('.ct-search-pagination__no-results').text()).toBe('No results.')
  })

  it('disables both buttons and does not emit update:page while loading', async () => {
    const wrapper = mount(SearchPagination, { props: { ...baseProps, loading: true } })

    expect(wrapper.find('.ct-search-pagination__button--previous').attributes('disabled')).toBeDefined()
    expect(wrapper.find('.ct-search-pagination__button--next').attributes('disabled')).toBeDefined()

    await wrapper.find('.ct-search-pagination__button--next').trigger('click')

    expect(wrapper.emitted('update:page')).toBeUndefined()
  })
})
