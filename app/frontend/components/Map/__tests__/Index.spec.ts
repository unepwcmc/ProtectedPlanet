import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'

const fakeMapInstance = {
  addControl: vi.fn(),
  on: vi.fn(),
  setStyle: vi.fn(),
  fitBounds: vi.fn(),
  resize: vi.fn(),
  getLayer: vi.fn(),
  getStyle: vi.fn(() => ({ layers: [] })),
  isStyleLoaded: vi.fn(() => true)
}

function MapImplementation() {
  return fakeMapInstance
}

vi.mock('maplibre-gl', () => ({
  Map: vi.fn(MapImplementation),
  AttributionControl: vi.fn(),
  NavigationControl: vi.fn(),
  Marker: vi.fn(),
  Popup: vi.fn(),
  setRTLTextPlugin: vi.fn()
}))

vi.mock('maplibregl-mapbox-request-transformer', () => ({
  isMapboxURL: (url: string) => url.startsWith('mapbox:'),
  transformMapboxUrl: vi.fn(),
  transformMapboxStyle: vi.fn(s => s)
}))

const { default: Map } = await import('@/components/Map/Index.vue')

const overlays = [
  {
    title: 'Terrestrial',
    layers: [{ id: 'layer-1', type: 'raster_tile' as const, url: 'https://tiles.example/{z}/{x}/{y}.png' }],
    id: 'terrestrial',
    type: 'raster_tile'
  }
]

beforeEach(() => {
  setActivePinia(createPinia())
})

describe('Map', () => {
  it('renders the mobile-only title, the map, and the panel with the disclaimer inside it', () => {
    const wrapper = mount(Map, {
      props: {
        title: 'Discover Protected Areas',
        overlays,
        disclaimer: { heading: 'Map Disclaimer', body: 'Some legal text' }
      }
    })

    expect(wrapper.find(':scope > .v-map-header').exists()).toBe(true)
    expect(wrapper.find('.map__mapbox').exists()).toBe(true)
    expect(wrapper.find('.v-map-filters').exists()).toBe(true)
    expect(wrapper.find('.v-map-filters--hidden').exists()).toBe(false)
    expect(wrapper.find('.v-map-filters .v-map-disclaimer__heading').text()).toBe('Map Disclaimer')
  })

  it('does not render a disclaimer when none is provided', () => {
    const wrapper = mount(Map, {
      props: { title: 'Discover Protected Areas', overlays }
    })

    expect(wrapper.find('.v-map-disclaimer').exists()).toBe(false)
  })

  it('forces the panel hidden when isHidden is passed', () => {
    const wrapper = mount(Map, {
      props: { title: 'Protected Area', overlays, isHidden: true }
    })

    expect(wrapper.find('.v-map-filters--hidden').exists()).toBe(true)
  })

  it('omits the standalone title header when showHeader is false', () => {
    const wrapper = mount(Map, {
      props: { title: 'Protected Area', overlays, showHeader: false }
    })

    expect(wrapper.find(':scope > .v-map-header').exists()).toBe(false)
    expect(wrapper.find('.v-map-filters .v-map-header').exists()).toBe(true)
  })

  it('renders the PA-search box when type and autocomplete copy are provided', () => {
    const wrapper = mount(Map, {
      props: {
        title: 'Discover Protected Areas',
        overlays,
        type: 'wdpca',
        autocompleteErrorMessages: { no_results: 'No results.', invalid_search_string: 'Too short.' },
        autocompletePlaceholder: 'Search for a Region, Country or Area'
      }
    })

    expect(wrapper.find('.v-map-pa-search').exists()).toBe(true)
  })

  it('omits the PA-search box when isHidden, or when type/autocomplete copy are not provided', () => {
    const withoutSearchProps = mount(Map, {
      props: { title: 'Protected Area', overlays, showHeader: false }
    })

    expect(withoutSearchProps.find('.v-map-pa-search').exists()).toBe(false)

    const hidden = mount(Map, {
      props: {
        title: 'Discover Protected Areas',
        overlays,
        isHidden: true,
        type: 'all',
        autocompleteErrorMessages: { no_results: 'No results.', invalid_search_string: 'Too short.' },
        autocompletePlaceholder: 'Search'
      }
    })

    expect(hidden.find('.v-map-pa-search').exists()).toBe(false)
  })
})
