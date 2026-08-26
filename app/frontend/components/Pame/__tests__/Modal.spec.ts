import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import PameModal from '@/components/Pame/Modal.vue'
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

describe('PameModal', () => {
  it('is inactive until isModalOpen is true', () => {
    const wrapper = mount(PameModal, { props: { text, modalContent: null, isModalOpen: false } })

    expect(wrapper.classes()).not.toContain('ct-pame-modal--active')
  })

  it('becomes active and shows the row detail once isModalOpen is true', () => {
    const wrapper = mount(PameModal, {
      props: { text, modalContent: item as PameEvaluationItem, isModalOpen: true }
    })

    expect(wrapper.classes()).toContain('ct-pame-modal--active')
    expect(wrapper.text()).toContain('2019')
    expect(wrapper.text()).toContain('A report')
  })

  it('emits close on the close button click', async () => {
    const wrapper = mount(PameModal, {
      props: { text, modalContent: item as PameEvaluationItem, isModalOpen: true }
    })

    await wrapper.find('.ct-pame-modal__close').trigger('click')

    expect(wrapper.emitted('close')).toHaveLength(1)
  })

  it('emits close on the backdrop click', async () => {
    const wrapper = mount(PameModal, {
      props: { text, modalContent: item as PameEvaluationItem, isModalOpen: true }
    })

    await wrapper.find('.ct-pame-modal__overlay').trigger('click')

    expect(wrapper.emitted('close')).toHaveLength(1)
  })

  it('carries the dialog semantics assistive tech needs to announce it as one', () => {
    const wrapper = mount(PameModal, {
      props: { text, modalContent: item as PameEvaluationItem, isModalOpen: true }
    })

    const dialog = wrapper.find('.ct-pame-modal__dialog')
    expect(dialog.attributes('role')).toBe('dialog')
    expect(dialog.attributes('aria-modal')).toBe('true')
    expect(dialog.attributes('aria-labelledby')).toBe('pame-modal-title')
    expect(wrapper.find('#pame-modal-title').text()).toBe('Source details')
  })

  it('closes on Escape and locks the page behind it while open', async () => {
    const wrapper = mount(PameModal, {
      props: { text, modalContent: item as PameEvaluationItem, isModalOpen: false },
      attachTo: document.body
    })

    await wrapper.setProps({ isModalOpen: true })
    expect(document.body.style.overflow).toBe('hidden')

    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', cancelable: true }))
    expect(wrapper.emitted('close')).toHaveLength(1)

    await wrapper.setProps({ isModalOpen: false })
    expect(document.body.style.overflow).toBe('')

    wrapper.unmount()
  })

  it('shows the year of submission based on source_year, matching the legacy field mapping bug fix', () => {
    const wrapper = mount(PameModal, {
      props: { text, modalContent: { ...item, source_year: 2021 } as PameEvaluationItem, isModalOpen: true }
    })

    expect(wrapper.text()).toContain('Year of submission')
    expect(wrapper.text()).toContain('2021')
  })
})
