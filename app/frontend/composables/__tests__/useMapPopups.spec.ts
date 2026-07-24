import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { ref } from 'vue'

const marker = { remove: vi.fn(), setLngLat: vi.fn().mockReturnThis(), addTo: vi.fn().mockReturnThis() }
const popup = {
  remove: vi.fn(),
  setLngLat: vi.fn().mockReturnThis(),
  setHTML: vi.fn().mockReturnThis(),
  setMaxWidth: vi.fn().mockReturnThis(),
  addTo: vi.fn().mockReturnThis()
}

vi.mock('maplibre-gl', () => ({
  Marker: vi.fn(function () { return marker }),
  Popup: vi.fn(function () { return popup })
}))

const { useMapPopups } = await import('@/composables/useMapPopups')

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
  vi.clearAllMocks()
})

afterEach(() => {
  document.head.innerHTML = ''
})

describe('useMapPopups', () => {
  it('queries services in order and stops at the first one that finds a feature', async () => {
    vi.mocked(fetch)
      .mockResolvedValueOnce(jsonResponse({ features: [] }))
      .mockResolvedValueOnce(jsonResponse({ features: [{ attributes: { name: 'My PA', site_id: '123' } }] }))

    const map = ref({})
    const { onClick } = useMapPopups(map as never, [{ url: '/service-a' }, { url: '/service-b' }])

    await onClick({ lngLat: { lng: 1, lat: 2 }, originalEvent: {} } as never)

    expect(fetch).toHaveBeenCalledTimes(2)
    expect(popup.setHTML).toHaveBeenCalledWith(expect.stringContaining('My PA'))
  })

  it('does nothing when no service finds a feature', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({ features: [] }))

    const map = ref({})
    const { onClick } = useMapPopups(map as never, [{ url: '/service-a' }])

    await onClick({ lngLat: { lng: 1, lat: 2 }, originalEvent: {} } as never)

    expect(popup.setHTML).not.toHaveBeenCalled()
  })

  it('removes existing markers and popups before adding new ones', () => {
    const map = ref({})
    const { addPopup, removeAllMarkersAndPopups } = useMapPopups(map as never, [])

    addPopup({ lng: 1, lat: 2 }, '<p>hi</p>')
    removeAllMarkersAndPopups()

    expect(marker.remove).toHaveBeenCalled()
    expect(popup.remove).toHaveBeenCalled()
  })
})
