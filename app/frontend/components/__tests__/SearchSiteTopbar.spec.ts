import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchSiteTopbar from '@/components/Search/SiteTopbar.vue'

describe('SearchSiteTopbar', () => {
  beforeEach(() => {
    delete (window as unknown as { location?: unknown }).location
    Object.defineProperty(window, 'location', { writable: true, configurable: true, value: { href: '' } })
  })

  it('renders a popout SearchSiteInput with the given placeholder', () => {
    const wrapper = mount(SearchSiteTopbar, {
      props: { endpoint: '/en/search?search_term=', placeholder: 'Search the site' }
    })

    expect(wrapper.find('.ct-search__input').attributes('placeholder')).toBe('Search the site')
    expect(wrapper.find('.ct-search__trigger').exists()).toBe(true)
  })

  it('navigates to endpoint + search term on submit', async () => {
    const wrapper = mount(SearchSiteTopbar, {
      props: { endpoint: '/en/search?search_term=', placeholder: 'Search the site' }
    })

    await wrapper.find('.ct-search__input').setValue('marine protected areas')
    await wrapper.find('.ct-search__input').trigger('keyup.enter')

    expect(window.location.href).toBe('/en/search?search_term=marine protected areas')
  })
})
