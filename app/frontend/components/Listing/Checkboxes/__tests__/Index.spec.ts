import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import Checkboxes from '@/components/Listing/Checkboxes/Index.vue'

const options = [
  { id: 'wdpa', title: 'WDPA' },
  { id: 'oecm', title: 'OECM' }
]

describe('Listing Checkboxes', () => {
  beforeEach(() => {
    window.gtag = vi.fn()
  })

  it('emits the selected ids on change', async () => {
    const wrapper = mount(Checkboxes, { props: { id: 'topics', options } })

    await wrapper.find('input[value="wdpa"]').setValue(true)

    expect(wrapper.emitted('update:options')?.[0]).toEqual([['wdpa']])
  })

  it('reflects preSelected values as checked on mount', () => {
    const wrapper = mount(Checkboxes, { props: { id: 'topics', options, preSelected: ['oecm'] } })

    expect((wrapper.find('input[value="oecm"]').element as HTMLInputElement).checked).toBe(true)
    expect((wrapper.find('input[value="wdpa"]').element as HTMLInputElement).checked).toBe(false)
  })

  it('clears all selections and re-emits when resetKey changes', async () => {
    const wrapper = mount(Checkboxes, { props: { id: 'topics', options, preSelected: ['wdpa'], resetKey: 0 } })

    await wrapper.setProps({ resetKey: 1 })

    expect((wrapper.find('input[value="wdpa"]').element as HTMLInputElement).checked).toBe(false)
    expect(wrapper.emitted('update:options')?.at(-1)).toEqual([[]])
  })

  it('fires a GA4 event with the selected titles when gaId is set', async () => {
    const wrapper = mount(Checkboxes, { props: { id: 'topics', gaId: 'Slug: news', options } })

    await wrapper.find('input[value="wdpa"]').setValue(true)

    expect(window.gtag).toHaveBeenCalledWith('event', 'click', {
      event_label: 'Slug: news - Checkbox(es): WDPA'
    })
  })

  it('does not fire a GA4 event when gaId is absent', async () => {
    const wrapper = mount(Checkboxes, { props: { id: 'topics', options } })

    await wrapper.find('input[value="wdpa"]').setValue(true)

    expect(window.gtag).not.toHaveBeenCalled()
  })
})
