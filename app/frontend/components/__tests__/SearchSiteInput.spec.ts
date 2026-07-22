import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchSiteInput from '@/components/Search/SiteInput.vue'

describe('SearchSiteInput', () => {
  it('starts closed when popout, and opens on trigger click', async () => {
    const wrapper = mount(SearchSiteInput, { props: { placeholder: 'Search', popout: true } })

    expect(wrapper.find('.search__pane').classes()).not.toContain('active')

    await wrapper.find('.search__trigger').trigger('click')
    expect(wrapper.find('.search__pane').classes()).toContain('active')
  })

  it('has no trigger and starts open when not popout', () => {
    const wrapper = mount(SearchSiteInput, { props: { placeholder: 'Search' } })

    expect(wrapper.find('.search__trigger').exists()).toBe(false)
    expect(wrapper.find('.search__pane').classes()).toContain('active')
  })

  it('pre-populates the search term', () => {
    const wrapper = mount(SearchSiteInput, {
      props: { placeholder: 'Search', prePopulatedSearchTerm: 'marine' }
    })

    expect((wrapper.find('.search__input').element as HTMLInputElement).value).toBe('marine')
  })

  it('emits submit:search on Enter with the current term', async () => {
    const wrapper = mount(SearchSiteInput, { props: { placeholder: 'Search' } })

    await wrapper.find('.search__input').setValue('coral reefs')
    await wrapper.find('.search__input').trigger('keyup.enter')

    expect(wrapper.emitted('submit:search')?.[0]).toEqual(['coral reefs'])
  })

  it('closes and clears the term via the close button (popout)', async () => {
    const wrapper = mount(SearchSiteInput, { props: { placeholder: 'Search', popout: true } })

    await wrapper.find('.search__trigger').trigger('click')
    await wrapper.find('.search__input').setValue('marine')

    await wrapper.find('.search__close').trigger('click')
    expect(wrapper.find('.search__pane').classes()).not.toContain('active')
    expect((wrapper.find('.search__input').element as HTMLInputElement).value).toBe('')
  })

  it('shows the close button once there is a search term when not popout', async () => {
    const wrapper = mount(SearchSiteInput, { props: { placeholder: 'Search' } })

    expect(wrapper.find('.search__close').attributes('style')).toContain('display: none')

    await wrapper.find('.search__input').setValue('marine')
    expect(wrapper.find('.search__close').attributes('style')).not.toContain('display: none')
  })
})
