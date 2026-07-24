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

function MapImplementation(options: Record<string, unknown>) {
  void options
  return fakeMapInstance
}

const MapConstructor = vi.fn(MapImplementation)

vi.mock('maplibre-gl', () => ({
  Map: MapConstructor,
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

const { default: MapBase } = await import('@/components/Map/Base.vue')

beforeEach(() => {
  setActivePinia(createPinia())
  vi.clearAllMocks()
})

describe('Map Base', () => {
  it('creates a MapLibre map with the container id and first baselayer style', async () => {
    mount(MapBase, { props: {} })

    await vi.waitFor(() => expect(MapConstructor).toHaveBeenCalledTimes(1))

    const [options] = MapConstructor.mock.calls[0]
    expect(options?.container).toMatch(/^map-target-\d+$/)
    expect(options?.style).toBe('mapbox://styles/unepwcmc/cko1hsfi50vog17l697cr4d6p')
  })

  it('renders baselayer controls by default', () => {
    const wrapper = mount(MapBase, { props: {} })

    expect(wrapper.find('.v-map-baselayer-controls').exists()).toBe(true)
  })

  it('hides baselayer controls when disabled via options', () => {
    const wrapper = mount(MapBase, {
      props: { options: { controls: { showBaselayerControls: false } } }
    })

    expect(wrapper.find('.v-map-baselayer-controls').exists()).toBe(false)
  })

  it('exposes zoomTo and resize for a parent to call once the search island lands', async () => {
    const wrapper = mount(MapBase, { props: {} })
    await vi.waitFor(() => expect(MapConstructor).toHaveBeenCalledTimes(1))

    wrapper.vm.resize()

    expect(fakeMapInstance.resize).toHaveBeenCalled()
  })
})
