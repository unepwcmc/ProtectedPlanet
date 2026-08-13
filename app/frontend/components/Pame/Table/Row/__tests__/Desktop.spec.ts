import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Row from '@/components/Pame/Table/Row/Desktop.vue'
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

describe('Pame Table Row Desktop', () => {
  it('shows "Multiple" when a field has more than one value', () => {
    const wrapper = mount(Row, { props: { item } })

    expect(wrapper.text()).toContain('Multiple')
  })

  it('emits open-modal with the row item when the metadata cell is clicked', async () => {
    const wrapper = mount(Row, { props: { item } })

    await wrapper.find('.ct-pame-table-row-desktop__cell--modal-trigger').trigger('click')

    expect(wrapper.emitted('open-modal')?.[0]).toEqual([item])
  })
})
