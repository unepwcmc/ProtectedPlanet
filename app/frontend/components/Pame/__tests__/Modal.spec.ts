import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import PameModal from '@/components/Pame/Modal.vue'
import { usePameStore } from '@/stores/usePameStore'
import type { PameEvaluationItem, PameModalTranslations } from '@/types/backend'

const text: PameModalTranslations = {
  modal_title: 'Source details',
  id: 'MetadataID',
  language: 'Language',
  responsible: 'Responsible party',
  title: 'Source Data Title',
  year: 'Year of submission'
}

const item: Partial<PameEvaluationItem> = {
  eff_metaid: 9,
  data_title: 'A report',
  resp_party: 'A party',
  source_year: 2019,
  language: 'English'
}

beforeEach(() => {
  setActivePinia(createPinia())
})

describe('PameModal', () => {
  it('is inactive until the store opens it', () => {
    const wrapper = mount(PameModal, { props: { text } })

    expect(wrapper.classes()).not.toContain('modal--active')
  })

  it('becomes active and shows the row detail once the store opens the modal', async () => {
    const wrapper = mount(PameModal, { props: { text } })
    usePameStore().openModal(item as PameEvaluationItem)
    await wrapper.vm.$nextTick()

    expect(wrapper.classes()).toContain('modal--active')
    expect(wrapper.text()).toContain('2019')
    expect(wrapper.text()).toContain('A report')
  })

  it('closes on the close button click', async () => {
    const wrapper = mount(PameModal, { props: { text } })
    const store = usePameStore()
    store.openModal(item as PameEvaluationItem)
    await wrapper.vm.$nextTick()

    await wrapper.find('.modal__close').trigger('click')

    expect(store.isModalOpen).toBe(false)
  })

  it('shows the year of submission based on source_year, matching the legacy field mapping bug fix', async () => {
    const wrapper = mount(PameModal, { props: { text } })
    usePameStore().openModal({ ...item, source_year: 2021 } as PameEvaluationItem)
    await wrapper.vm.$nextTick()

    expect(wrapper.text()).toContain('Year of submission')
    expect(wrapper.text()).toContain('2021')
  })
})
