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
    const res = await getJsonExternal<{ extent: Extent }>(boundsUrl.url)

    if (res.extent) {
      initBounds.value = getBoundsFromExtent(res.extent, boundsUrl.padding)
    }

    initMap()
  }

  function fitMapToBounds(extent: Extent, padding?: [number, number, number]) {
    map.value?.fitBounds(getBoundsFromExtent(extent, padding))
  }

  async function zoomTo(options: ZoomToOptions) {
    const res = await getJsonExternal<{ extent: Extent }>(options.extent_url.url)

    if (!res.extent) return

    fitMapToBounds(res.extent, options.extent_url.padding)

    if (options.name && options.addPopup) {
      const coords = {
        lng: (res.extent.xmin + res.extent.xmax) / 2,
        lat: (res.extent.ymin + res.extent.ymax) / 2
      }

      onPopupFromExtent?.(coords, options)
    }
  }

  return { initBounds, initBoundingBoxAndMap, zoomTo, fitMapToBounds, getBoundsFromExtent }
}
