import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import Row from '@/components/Pame/Table/Row/Index.vue'
import { usePameStore } from '@/stores/usePameStore'
import type { PameEvaluationItem } from '@/types/backend'

const item: PameEvaluationItem = {
  id: 1,
  asmt_id: 'A1',
  site_id: 555,
  site_pid: '555',
  pa_site_url: '/555',
  country: ['Kenya', 'Uganda'],
  method: 'Site visit',
  asmt_year: '2020',
  asmt_url: 'https://example.com/report',
  eff_metaid: 9,
  source_id: 9,
  name: 'Test Area',
  designation: 'National Park',
  data_title: 'Title',
  resp_party: 'Party',
  language: 'English',
  source_year: 2019
}

beforeEach(() => {
  setActivePinia(createPinia())
})

describe('Pame Table Row', () => {
  it('shows "Multiple" when a field has more than one value', () => {
    const wrapper = mount(Row, { props: { item } })

    expect(wrapper.text()).toContain('Multiple')
  })

  it('opens the pame store modal with the row item when the metadata cell is clicked', async () => {
    const wrapper = mount(Row, { props: { item } })
    const store = usePameStore()

    await wrapper.find('.table__cell-modal-trigger').trigger('click')

    expect(store.isModalOpen).toBe(true)
    expect(store.modalContent).toEqual(item)
  })
})
