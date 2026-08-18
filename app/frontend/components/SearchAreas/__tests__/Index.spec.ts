import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import SearchAreas from '@/components/SearchAreas/Index.vue'

describe('SearchAreas', () => {
  const originalLocation = window.location

  beforeEach(() => {
    Object.defineProperty(window, 'location', {
      writable: true,
      value: { ...originalLocation, href: '' }
    })
  })

  afterEach(() => {
    Object.defineProperty(window, 'location', { writable: true, value: originalLocation })
  })

  it('redirects to the search-areas results url with the submitted term', async () => {
    const wrapper = mount(SearchAreas, {
      props: {
        config: { id: 'all', placeholder: 'Search protected areas' },
        endpointAutocomplete: '/search/autocomplete',
        endpointSearch: '/search-areas?search_term=SEARCHTERM'
      }
    })

    await wrapper.find('input').setValue('yosemite')
    await wrapper.find('input').trigger('keyup.enter')

    expect(window.location.href).toBe('/search-areas?search_term=yosemite')
  })
})
