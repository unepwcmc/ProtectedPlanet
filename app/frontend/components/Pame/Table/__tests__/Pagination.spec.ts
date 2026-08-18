import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Pagination from '@/components/Pame/Table/Pagination.vue'

describe('Pame Table Pagination', () => {
  it('shows the no-results message when there are no items', () => {
    const wrapper = mount(Pagination, {
      props: { currentPage: 1, isFetching: false, itemsPerPage: 50, totalItems: 0, totalPages: 0 }
    })

    expect(wrapper.text()).toContain('There are no records matching the selected filters')
  })

  it('emits the next page number on next', async () => {
    const wrapper = mount(Pagination, {
      props: { currentPage: 1, isFetching: false, itemsPerPage: 50, totalItems: 120, totalPages: 3 }
    })

    await wrapper.find('.ct-pame-table-pagination__button--next').trigger('click')

    expect(wrapper.emitted('requestItems')?.[0]).toEqual([2])
  })

  it('does nothing when previous is clicked on the first page', async () => {
    const wrapper = mount(Pagination, {
      props: { currentPage: 1, isFetching: false, itemsPerPage: 50, totalItems: 120, totalPages: 3 }
    })

    await wrapper.find('.ct-pame-table-pagination__button--previous').trigger('click')

    expect(wrapper.emitted('requestItems')).toBeUndefined()
  })

  it('disables both buttons and ignores clicks while a PAME request is in flight', async () => {
    const wrapper = mount(Pagination, {
      props: { currentPage: 2, isFetching: true, itemsPerPage: 50, totalItems: 120, totalPages: 3 }
    })

    expect(wrapper.find('.ct-pame-table-pagination__button--next').attributes('disabled')).toBeDefined()
    expect(wrapper.find('.ct-pame-table-pagination__button--previous').attributes('disabled')).toBeDefined()

    await wrapper.find('.ct-pame-table-pagination__button--next').trigger('click')

    expect(wrapper.emitted('requestItems')).toBeUndefined()
  })
})
