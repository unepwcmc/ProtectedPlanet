import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchSiteInput from '@/components/Search/SiteInput.vue'

describe('SearchSiteInput', () => {
  it('starts closed when popout, and opens on trigger click', async () => {
    const wrapper = mount(SearchSiteInput, { props: { placeholder: 'Search', popout: true } })

    expect(wrapper.find('.ct-search__pane').classes()).not.toContain('ct-search__pane--popout-active')

    await wrapper.find('.ct-search__trigger').trigger('click')
    expect(wrapper.find('.ct-search__pane').classes()).toContain('ct-search__pane--popout-active')
  })

  it('has no trigger and starts open when not popout', () => {
    const wrapper = mount(SearchSiteInput, { props: { placeholder: 'Search' } })

    expect(wrapper.find('.ct-search__trigger').exists()).toBe(false)
    expect(wrapper.find('.ct-search__pane').classes()).toContain('ct-search__pane--popout-active')
  })

  it('has no close button when not popout', () => {
    const wrapper = mount(SearchSiteInput, { props: { placeholder: 'Search' } })

    expect(wrapper.find('.ct-search__close').exists()).toBe(false)
  })

  it('closes the popout via the close button', async () => {
    const wrapper = mount(SearchSiteInput, { props: { placeholder: 'Search', popout: true } })

    await wrapper.find('.ct-search__trigger').trigger('click')
    expect(wrapper.find('.ct-search__pane').classes()).toContain('ct-search__pane--popout-active')

    await wrapper.find('.ct-search__close').trigger('click')
    expect(wrapper.find('.ct-search__pane').classes()).not.toContain('ct-search__pane--popout-active')
  })

  it('pre-populates the search term', () => {
    const wrapper = mount(SearchSiteInput, {
      props: { placeholder: 'Search', prePopulatedSearchTerm: 'marine' }
    })

    expect((wrapper.find('.ct-search__input').element as HTMLInputElement).value).toBe('marine')
  })

  it('emits submit:search on Enter with the current term', async () => {
    const wrapper = mount(SearchSiteInput, { props: { placeholder: 'Search' } })

    await wrapper.find('.ct-search__input').setValue('coral reefs')
    await wrapper.find('.ct-search__input').trigger('keyup.enter')

    expect(wrapper.emitted('submit:search')?.[0]).toEqual(['coral reefs'])
  })

  it('emits submit:search via the submit button (popout)', async () => {
    const wrapper = mount(SearchSiteInput, { props: { placeholder: 'Search', popout: true } })

    await wrapper.find('.ct-search__trigger').trigger('click')
    await wrapper.find('.ct-search__input').setValue('marine')

    await wrapper.find('.ct-search__submit').trigger('click')
    expect(wrapper.emitted('submit:search')?.[0]).toEqual(['marine'])
  })

  it('shows the submit button once there is a search term when not popout', async () => {
    const wrapper = mount(SearchSiteInput, { props: { placeholder: 'Search' } })

    expect(wrapper.find('.ct-search__submit').attributes('style')).toContain('display: none')

    await wrapper.find('.ct-search__input').setValue('marine')
    expect(wrapper.find('.ct-search__submit').attributes('style')).not.toContain('display: none')
  })

  it('closes the popout when clicking outside', async () => {
    const wrapper = mount(SearchSiteInput, {
      props: { placeholder: 'Search', popout: true },
      attachTo: document.body
    })

    await wrapper.find('.ct-search__trigger').trigger('click')
    expect(wrapper.find('.ct-search__pane').classes()).toContain('ct-search__pane--popout-active')

    // onClickOutside guards against double-firing within the same tick (see
    // vueuse-adoption memory) — wait a macrotask so it doesn't ignore this click.
    await new Promise(resolve => setTimeout(resolve, 0))
    document.body.click()
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.ct-search__pane').classes()).not.toContain('ct-search__pane--popout-active')

    wrapper.unmount()
  })

  it('disables the input and does not emit submit:search when disabled', async () => {
    const wrapper = mount(SearchSiteInput, { props: { placeholder: 'Search', disabled: true } })

    expect(wrapper.find('.ct-search__input').attributes('disabled')).toBeDefined()

    await wrapper.find('.ct-search__input').setValue('marine')
    await wrapper.find('.ct-search__input').trigger('keyup.enter')

    expect(wrapper.emitted('submit:search')).toBeUndefined()
  })
})
