// Vue3 port of app/javascript/components/map/mixins/mixin-bounding-box.js
import { ref, type Ref } from 'vue'
import type { LngLatBoundsLike, Map as MapLibreMap } from 'maplibre-gl'
import { getJsonExternal } from '@/lib/http'

export interface BoundsUrl {
  url: string
  padding?: [number, number, number]
}

export interface ZoomToOptions {
  extent_url: BoundsUrl
  name?: string
  addPopup?: boolean
  [key: string]: unknown
}

interface Extent {
  xmin: number
  xmax: number
  ymin: number
  ymax: number
}

export default function (
  map: Ref<MapLibreMap | null>,
  onPopupFromExtent?: (coords: { lng: number, lat: number }, options: ZoomToOptions) => void
) {
  const initBounds = ref<LngLatBoundsLike | null>(null)

  // ArcGIS answers an extent query for a site_id it doesn't hold with a
  // perfectly well-formed extent whose corners are the *strings* "NaN" - which
  // happens whenever our DB is ahead of the published service (a newly added
  // site, a retired one, a sync lag). That object is truthy and its members
  // survive arithmetic as NaN, so the bounds reached MapLibre's constructor and
  // threw "Invalid LngLat object: (NaN, NaN)" - taking out the whole map, and
  // with it the PDF rasterizer, which waited out its entire budget for a
  // readiness signal the dead map could no longer send. Numbers also arrive as
  // strings for some fields, hence coercing rather than type-checking.
  function normaliseExtent(extent: Extent | undefined | null): Extent | null {
    if (!extent) return null

    const corners = (['xmin', 'xmax', 'ymin', 'ymax'] as const).map(key => Number(extent[key]))
    if (!corners.every(Number.isFinite)) return null

    const [xmin, xmax, ymin, ymax] = corners
    return { xmin, xmax, ymin, ymax }
  }

  function getBoundsFromExtent(extent: Extent, padding: [number, number, number] = [5, 5, 5]): LngLatBoundsLike {
    // handle PAs split by the international date line
    const isDateLineSplit = extent.xmin < 179 && extent.xmax > 179

    return [
      [
        isDateLineSplit ? 180 - padding[0] : Math.max(extent.xmin - padding[0], -180),
        Math.max(extent.ymin - padding[2], -90)
      ],
      [
        isDateLineSplit ? 180 + padding[1] : Math.min(extent.xmax + padding[1], 180),
        Math.min(extent.ymax + padding[2], 90)
      ]
    ]
  }

  async function initBoundingBoxAndMap(boundsUrl: BoundsUrl | undefined, initMap: () => void) {
    if (!boundsUrl) {
      initMap()
      return
    }

    // These are external ArcGIS hosts, not our Rails app — sending our CSRF
    // header fails their CORS preflight (same fix as useMapPopups.ts).
    // Wrapped because initMap() below MUST still run if the lookup fails: an
    // unreachable ArcGIS would otherwise leave the map unbuilt and the PDF
    // rasterizer waiting for a readiness signal that can never come. A map at
    // its default view is a far better outcome than no map at all.
    let extent: Extent | null = null

    try {
      const res = await getJsonExternal<{ extent: Extent }>(boundsUrl.url)
      extent = normaliseExtent(res.extent)
    } catch (error) {
      console.error(`Could not fetch map bounds from ${boundsUrl.url}`, error)
    }

    if (extent) initBounds.value = getBoundsFromExtent(extent, boundsUrl.padding)

    initMap()
  }

  function fitMapToBounds(extent: Extent, padding?: [number, number, number]) {
    map.value?.fitBounds(getBoundsFromExtent(extent, padding))
  }

  async function zoomTo(options: ZoomToOptions) {
    const res = await getJsonExternal<{ extent: Extent }>(options.extent_url.url)
    const extent = normaliseExtent(res.extent)

    if (!extent) return

    fitMapToBounds(extent, options.extent_url.padding)

    if (options.name && options.addPopup) {
      const coords = {
        lng: (extent.xmin + extent.xmax) / 2,
        lat: (extent.ymin + extent.ymax) / 2
      }

      onPopupFromExtent?.(coords, options)
    }
  }

  return { initBounds, initBoundingBoxAndMap, zoomTo, fitMapToBounds, getBoundsFromExtent }
}
