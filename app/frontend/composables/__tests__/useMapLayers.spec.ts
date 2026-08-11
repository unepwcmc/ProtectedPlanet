import { describe, it, expect, vi } from 'vitest'
import { ref } from 'vue'
import useMapLayers from from '@/composables/useMapLayers'

function fakeMap(overrides: Partial<Record<string, unknown>> = {}) {
  const layers: Record<string, { visibility?: string }> = {}

  return {
    getLayer: vi.fn((id: string) => layers[id]),
    addLayer: vi.fn((options: { id: string, layout?: { visibility?: string } }) => {
      layers[options.id] = { visibility: options.layout?.visibility }
    }),
    setLayoutProperty: vi.fn((id: string, _prop: string, value: string) => {
      layers[id] = { ...layers[id], visibility: value }
    }),
    getStyle: vi.fn(() => ({
      layers: [
        { id: 'background', type: 'background' },
        { id: 'admin-0-boundary', type: 'line' },
        { id: 'place-labels', type: 'symbol' }
      ]
    })),
    isStyleLoaded: vi.fn(() => true),
    ...overrides
  }
}

describe('useMapLayers', () => {
  it('finds the first admin boundary layer as the foreground anchor', () => {
    const map = ref(fakeMap())
    const { setFirstForegroundLayerId, firstForegroundLayerId } = useMapLayers(map as never)

    setFirstForegroundLayerId()

    expect(firstForegroundLayerId.value).toBe('admin-0-boundary')
  })

  it('falls back to the first symbol layer when no admin boundary exists', () => {
    const map = ref(fakeMap({
      getStyle: vi.fn(() => ({
        layers: [{ id: 'background', type: 'background' }, { id: 'place-labels', type: 'symbol' }]
      }))
    }))
    const { setFirstForegroundLayerId, firstForegroundLayerId } = useMapLayers(map as never)

    setFirstForegroundLayerId()

    expect(firstForegroundLayerId.value).toBe('place-labels')
  })

  it('adds a raster tile layer beneath the foreground anchor when shown for the first time', async () => {
    const map = ref(fakeMap())
    const { setFirstForegroundLayerId, showLayers } = useMapLayers(map as never)
    setFirstForegroundLayerId()

    showLayers([{ id: 'wdpa', type: 'raster_tile', url: 'https://tiles.example/{z}/{x}/{y}.png' }])

    await vi.waitFor(() => {
      expect(map.value.addLayer).toHaveBeenCalledWith(
        expect.objectContaining({ id: 'wdpa', type: 'raster' }),
        'admin-0-boundary'
      )
    })
  })

  it('sets visibility to none for layers passed to hideLayers', () => {
    const map = ref(fakeMap())
    map.value.getLayer = vi.fn(() => ({ visibility: 'visible' }))
    const { hideLayers } = useMapLayers(map as never)

    hideLayers([{ id: 'wdpa' }])

    expect(map.value.setLayoutProperty).toHaveBeenCalledWith('wdpa', 'visibility', 'none')
  })
})
