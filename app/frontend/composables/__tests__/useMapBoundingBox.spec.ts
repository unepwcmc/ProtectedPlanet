import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { ref } from 'vue'
import useMapBoundingBox from '@/composables/useMapBoundingBox'

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

  // For a site_id it does not hold, ArcGIS returns corners that are the strings
  // "NaN". Unchecked they reached MapLibre's constructor, killing the map and
  // hanging the PDF rasterizer.
  it('ignores an extent whose corners are not finite numbers and still builds the map', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({
      extent: { xmin: 'NaN', xmax: 'NaN', ymin: 'NaN', ymax: 'NaN' }
    }))
    const map = ref(null)
    const { initBoundingBoxAndMap, initBounds } = useMapBoundingBox(map as never)
    const initMap = vi.fn()

    await initBoundingBoxAndMap({ url: '/extent' }, initMap)

    expect(initBounds.value).toBeNull()
    expect(initMap).toHaveBeenCalledOnce()
  })

  it('accepts an extent whose corners arrive as numeric strings', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({
      extent: { xmin: '-10', xmax: '10', ymin: '-5', ymax: '5' }
    }))
    const map = ref(null)
    const { initBoundingBoxAndMap, initBounds } = useMapBoundingBox(map as never)

    await initBoundingBoxAndMap({ url: '/extent' }, vi.fn())

    expect(initBounds.value).toEqual([[-15, -10], [15, 10]])
  })

  it('still builds the map when the bounds lookup fails outright', async () => {
    vi.mocked(fetch).mockRejectedValue(new Error('ArcGIS unreachable'))
    const map = ref(null)
    const { initBoundingBoxAndMap, initBounds } = useMapBoundingBox(map as never)
    const initMap = vi.fn()

    await initBoundingBoxAndMap({ url: '/extent' }, initMap)

    expect(initBounds.value).toBeNull()
    expect(initMap).toHaveBeenCalledOnce()
  })

  it('does not move the map when zoomTo gets a non-finite extent', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({
      extent: { xmin: 'NaN', xmax: 'NaN', ymin: 'NaN', ymax: 'NaN' }
    }))
    const fitBounds = vi.fn()
    const map = ref({ fitBounds })
    const onPopupFromExtent = vi.fn()
    const { zoomTo } = useMapBoundingBox(map as never, onPopupFromExtent)

    await zoomTo({ extent_url: { url: '/extent' }, name: 'My PA', addPopup: true })

    expect(fitBounds).not.toHaveBeenCalled()
    expect(onPopupFromExtent).not.toHaveBeenCalled()
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
