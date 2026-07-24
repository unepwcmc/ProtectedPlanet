import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { ref } from 'vue'
import { useMapBoundingBox } from '@/composables/useMapBoundingBox'

function jsonResponse(data: unknown) {
  return { ok: true, status: 200, json: () => Promise.resolve(data) } as Response
}

function meta() {
  const tag = document.createElement('meta')
  tag.name = 'csrf-token'
  tag.content = 'test-token'
  document.head.appendChild(tag)
}

beforeEach(() => {
  vi.stubGlobal('fetch', vi.fn())
  meta()
})

afterEach(() => {
  document.head.innerHTML = ''
})

describe('useMapBoundingBox', () => {
  it('computes bounds from an extent with default padding', () => {
    const map = ref(null)
    const { getBoundsFromExtent } = useMapBoundingBox(map as never)

    const bounds = getBoundsFromExtent({ xmin: -10, xmax: 10, ymin: -5, ymax: 5 })

    expect(bounds).toEqual([[-15, -10], [15, 10]])
  })

  it('widens the antimeridian split case to +/-180 instead of wrapping', () => {
    const map = ref(null)
    const { getBoundsFromExtent } = useMapBoundingBox(map as never)

    const bounds = getBoundsFromExtent({ xmin: -179.5, xmax: 179.8, ymin: -1, ymax: 1 }, [5, 5, 5]) as number[][]

    expect(bounds[0][0]).toBe(175)
    expect(bounds[1][0]).toBe(185)
  })

  it('fetches bounds and calls initMap once the extent resolves', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ extent: { xmin: -10, xmax: 10, ymin: -5, ymax: 5 } }))
    const map = ref(null)
    const { initBoundingBoxAndMap, initBounds } = useMapBoundingBox(map as never)
    const initMap = vi.fn()

    await initBoundingBoxAndMap({ url: '/extent' }, initMap)

    expect(initMap).toHaveBeenCalledOnce()
    expect(initBounds.value).toEqual([[-15, -10], [15, 10]])
  })

  it('calls initMap immediately when no boundsUrl is given', async () => {
    const map = ref(null)
    const { initBoundingBoxAndMap } = useMapBoundingBox(map as never)
    const initMap = vi.fn()

    await initBoundingBoxAndMap(undefined, initMap)

    expect(initMap).toHaveBeenCalledOnce()
    expect(fetch).not.toHaveBeenCalled()
  })

  it('fits the map to bounds and invokes the popup callback when zoomTo resolves with addPopup', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ extent: { xmin: -10, xmax: 10, ymin: -5, ymax: 5 } }))
    const fitBounds = vi.fn()
    const map = ref({ fitBounds })
    const onPopupFromExtent = vi.fn()
    const { zoomTo } = useMapBoundingBox(map as never, onPopupFromExtent)

    await zoomTo({ extent_url: { url: '/extent' }, name: 'My PA', addPopup: true })

    expect(fitBounds).toHaveBeenCalledWith([[-15, -10], [15, 10]])
    expect(onPopupFromExtent).toHaveBeenCalledWith({ lng: 0, lat: 0 }, expect.objectContaining({ name: 'My PA' }))
  })
})
