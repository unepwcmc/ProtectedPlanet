import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'

const fakeMapInstance = {
  addControl: vi.fn(),
  on: vi.fn(),
  setStyle: vi.fn(),
  fitBounds: vi.fn(),
  resize: vi.fn(),
  getLayer: vi.fn(),
  addLayer: vi.fn(),
  addSource: vi.fn(),
  getSource: vi.fn(),
  getStyle: vi.fn((): { layers: Array<{ id: string, type: string }> } => ({ layers: [] })),
  isStyleLoaded: vi.fn(() => true)
}

function MapImplementation(options: Record<string, unknown>) {
  void options
  return fakeMapInstance
}

const MapConstructor = vi.fn(MapImplementation)
const MarkerConstructor = vi.fn(function () {
  return { setLngLat: vi.fn().mockReturnThis(), addTo: vi.fn().mockReturnThis(), remove: vi.fn() }
})
const PopupConstructor = vi.fn(function () {
  return {
    setLngLat: vi.fn().mockReturnThis(),
    setHTML: vi.fn().mockReturnThis(),
    setMaxWidth: vi.fn().mockReturnThis(),
    addTo: vi.fn().mockReturnThis(),
    remove: vi.fn()
  }
})

vi.mock('maplibre-gl', () => ({
  Map: MapConstructor,
  AttributionControl: vi.fn(),
  NavigationControl: vi.fn(),
  Marker: MarkerConstructor,
  Popup: PopupConstructor,
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

const { default: MapBase } = await import('@/components/Map/Base.vue')

// Stand-in for the browser's IntersectionObserver so a test can trigger the
// "container became visible" path itself — same pattern as Counter.spec.ts.
class FakeIntersectionObserver {
  static instances: FakeIntersectionObserver[] = []
  callback: IntersectionObserverCallback

  constructor(callback: IntersectionObserverCallback) {
    this.callback = callback
    FakeIntersectionObserver.instances.push(this)
  }

  observe = vi.fn()
  disconnect = vi.fn()
  unobserve = vi.fn()

  trigger(isIntersecting: boolean) {
    this.callback([{ isIntersecting } as IntersectionObserverEntry], this as unknown as IntersectionObserver)
  }
}

beforeEach(() => {
  setActivePinia(createPinia())
  vi.clearAllMocks()
  FakeIntersectionObserver.instances = []
  vi.stubGlobal('IntersectionObserver', FakeIntersectionObserver)
})

afterEach(() => {
  vi.unstubAllGlobals()
})

describe('Map Base', () => {
  it('creates a MapLibre map with the container id and first baselayer style', async () => {
    mount(MapBase, { props: {} })

    await vi.waitFor(() => expect(MapConstructor).toHaveBeenCalledTimes(1))

    const [options] = MapConstructor.mock.calls[0]
    expect(options?.container).toMatch(/^map-target-\d+$/)
    expect(options?.style).toBe('mapbox://styles/unepwcmc/cko1hsfi50vog17l697cr4d6p')
  })

  // The pinia store is app-wide and survives Turbo Drive navigation, while this
  // island is rebuilt on every page. addOverlay is idempotent, so on a second visit
  // the overlay is already stored, visibleLayers never changes, and the
  // visibleLayers watcher never fires -- the new map has to sync itself to the
  // store on init instead. Without that, the highlighted area disappeared from
  // every map after the first one.
  it('applies overlays already in the store to a newly created map', async () => {
    const { useMapStore } = await import('@/stores/useMapStore')
    const store = useMapStore()
    store.addOverlay({
      id: 'wdpa',
      layers: [{ id: 'wdpa-poly', type: 'raster_tile', url: 'https://x/{z}/{x}/{y}' }]
    })

    fakeMapInstance.getLayer.mockReturnValue(undefined)
    // addLayerBeneathBoundariesAndLabels waits for a foreground layer id before
    // inserting; give the style one so it resolves on the first 200ms poll instead
    // of burning all 10 attempts.
    fakeMapInstance.getStyle.mockReturnValue({ layers: [{ id: 'admin-boundary', type: 'line' }] })
    // Baselayer controls are disabled on purpose: their selectedBaselayer watcher
    // also calls showLayers, which would make this pass regardless of the init sync.
    mount(MapBase, { props: { options: { controls: { showBaselayerControls: false } } } })
    await vi.waitFor(() => expect(MapConstructor).toHaveBeenCalledTimes(1))

    // initMap registers the style.load handler; fire it as MapLibre would.
    const styleLoad = fakeMapInstance.on.mock.calls.find(c => c[0] === 'style.load')
    expect(styleLoad, 'a style.load handler must be registered').toBeTruthy()
    styleLoad![1]()

    // showLayers defers through executeAfterStyleLoad, which polls — so this is async.
    await vi.waitFor(() => expect(fakeMapInstance.addLayer).toHaveBeenCalled(), { timeout: 4000 })
  })

  it('renders baselayer controls by default', () => {
    const wrapper = mount(MapBase, { props: {} })

    expect(wrapper.find('.ct-map-baselayer-controls').exists()).toBe(true)
  })

  it('hides baselayer controls when disabled via options', () => {
    const wrapper = mount(MapBase, {
      props: { options: { controls: { showBaselayerControls: false } } }
    })

    expect(wrapper.find('.ct-map-baselayer-controls').exists()).toBe(false)
  })

  it('exposes zoomTo and resize for the panel search box to call', async () => {
    const wrapper = mount(MapBase, { props: {} })
    await vi.waitFor(() => expect(MapConstructor).toHaveBeenCalledTimes(1))

    wrapper.vm.resize()

    expect(fakeMapInstance.resize).toHaveBeenCalled()
  })

  it('resizes the map once its (initially hidden, e.g. inactive-tab) container becomes visible', async () => {
    mount(MapBase, { props: {} })
    await vi.waitFor(() => expect(MapConstructor).toHaveBeenCalledTimes(1))

    expect(FakeIntersectionObserver.instances).toHaveLength(1)
    FakeIntersectionObserver.instances[0].trigger(true)

    expect(fakeMapInstance.resize).toHaveBeenCalled()
  })

  it('opens a popup with the same name/site_id/site_pid attributes as the click-to-query popup when zoomTo resolves with addPopup', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve({ extent: { xmin: -10, xmax: 10, ymin: -5, ymax: 5 } })
    }))

    const wrapper = mount(MapBase, { props: {} })
    await vi.waitFor(() => expect(MapConstructor).toHaveBeenCalledTimes(1))

    await wrapper.vm.zoomTo({
      extent_url: { url: '/extent' },
      name: 'Yosemite',
      addPopup: true,
      id: 555,
      is_pa: true,
      site_pid: '555_A'
    })

    const html = PopupConstructor.mock.results[0].value.setHTML.mock.calls[0][0]
    expect(html).toContain('Yosemite')
    expect(html).toContain('555_A')
    expect(html).toContain('href="/555"')

    vi.unstubAllGlobals()
  })

  it('omits the site_id link when the search result is not a PA (region/country)', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve({ extent: { xmin: -10, xmax: 10, ymin: -5, ymax: 5 } })
    }))

    const wrapper = mount(MapBase, { props: {} })
    await vi.waitFor(() => expect(MapConstructor).toHaveBeenCalledTimes(1))

    await wrapper.vm.zoomTo({
      extent_url: { url: '/extent' },
      name: 'Colombia',
      addPopup: true,
      id: 'COL',
      is_pa: false,
      site_pid: null
    })

    const html = PopupConstructor.mock.results[0].value.setHTML.mock.calls[0][0]
    expect(html).toContain('Colombia')
    expect(html).not.toContain('href=')

    vi.unstubAllGlobals()
  })
})
