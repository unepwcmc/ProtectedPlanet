import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'

const fakeMapInstance = {
  addControl: vi.fn(),
  on: vi.fn(),
  off: vi.fn(),
  once: vi.fn(),
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
  setRTLTextPlugin: vi.fn(),
  // useMapInstance calls this at module scope to point MapLibre at the
  // Vite-emitted worker; without it here the module throws on import.
  setWorkerUrl: vi.fn()
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

    expect(wrapper.find(':scope > .ct-map-header').exists()).toBe(true)
    expect(wrapper.find('.ct-map-base__canvas').exists()).toBe(true)
    expect(wrapper.find('.ct-map-panel').exists()).toBe(true)
    expect(wrapper.find('.ct-map-panel--hidden').exists()).toBe(false)
    expect(wrapper.find('.ct-map-panel .ct-map-disclaimer__heading').text()).toBe('Map Disclaimer')
  })

  it('does not render a disclaimer when none is provided', () => {
    const wrapper = mount(Map, {
      props: { title: 'Discover Protected Areas', overlays }
    })

    expect(wrapper.find('.ct-map-disclaimer').exists()).toBe(false)
  })

  it('forces the panel hidden when isHidden is passed', () => {
    const wrapper = mount(Map, {
      props: { title: 'Protected Area', overlays, isHidden: true }
    })

    expect(wrapper.find('.ct-map-panel--hidden').exists()).toBe(true)
  })

  it('omits the standalone title header when showHeader is false', () => {
    const wrapper = mount(Map, {
      props: { title: 'Protected Area', overlays, showHeader: false }
    })

    expect(wrapper.find(':scope > .ct-map-header').exists()).toBe(false)
    expect(wrapper.find('.ct-map-panel .ct-map-header').exists()).toBe(true)
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

    expect(wrapper.find('.ct-map-pa-search').exists()).toBe(true)
  })

  it('omits the PA-search box when isHidden, or when type/autocomplete copy are not provided', () => {
    const withoutSearchProps = mount(Map, {
      props: { title: 'Protected Area', overlays, showHeader: false }
    })

    expect(withoutSearchProps.find('.ct-map-pa-search').exists()).toBe(false)

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

    expect(hidden.find('.ct-map-pa-search').exists()).toBe(false)
  })

  // Every protected-area page ships an overlay with the SAME id
  // ("individual_site") but a DIFFERENT site-specific geometry URL, and the pinia
  // store survives Turbo Drive navigation. addOverlay is idempotent by id, so
  // without clearing first the second site kept the FIRST site's polygon --
  // rendered off-screen, which looked like "the highlight disappeared".
  it('clears overlays left over from a previously visited map page', async () => {
    const { useMapStore } = await import('@/stores/useMapStore')
    const store = useMapStore()
    store.addOverlay({
      id: 'individual_site',
      layers: [{ id: 'individual_site_0', type: 'raster_data', url: 'https://old/site_id=1' }]
    })
    expect(store.visibleLayers).toHaveLength(1)

    mount(Map, { props: { title: 'Protected Area', overlays } })

    // onBeforeMount runs before any child registers this page's own overlay.
    expect(store.visibleLayers.some(l => l.url === 'https://old/site_id=1')).toBe(false)
  })
})
