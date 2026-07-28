import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import Pagination from '@/components/Pame/Table/Pagination.vue'
import { usePameStore } from '@/stores/usePameStore'

beforeEach(() => {
  setActivePinia(createPinia())
})

describe('Pame Table Pagination', () => {
  it('shows the no-results message when there are no items', () => {
    const wrapper = mount(Pagination, {
      props: { currentPage: 1, itemsPerPage: 50, totalItems: 0, totalPages: 0 }
    })

    expect(wrapper.text()).toContain('There are no records matching the selected filters')
  })

  it('advances the requested page in the store and requests items on next', async () => {
    const wrapper = mount(Pagination, {
      props: { currentPage: 1, itemsPerPage: 50, totalItems: 120, totalPages: 3 }
    })
    const store = usePameStore()

    await wrapper.find('.pagination__button--next').trigger('click')

    expect(store.requestedPage).toBe(2)
    expect(wrapper.emitted('requestItems')).toHaveLength(1)
  })

  it('does nothing when previous is clicked on the first page', async () => {
    const wrapper = mount(Pagination, {
      props: { currentPage: 1, itemsPerPage: 50, totalItems: 120, totalPages: 3 }
    })
    const store = usePameStore()

    await wrapper.find('.pagination__button--previous').trigger('click')

    expect(store.requestedPage).toBe(1)
    expect(wrapper.emitted('requestItems')).toBeUndefined()
  })

  it('disables both buttons and ignores clicks while a PAME request is in flight', async () => {
    usePameStore().setFetching(true)
    const wrapper = mount(Pagination, {
      props: { currentPage: 2, itemsPerPage: 50, totalItems: 120, totalPages: 3 }
    })

    expect(wrapper.find('.pagination__button--next').attributes('disabled')).toBeDefined()
    expect(wrapper.find('.pagination__button--previous').attributes('disabled')).toBeDefined()

    await wrapper.find('.pagination__button--next').trigger('click')

    expect(wrapper.emitted('requestItems')).toBeUndefined()
  })
})
