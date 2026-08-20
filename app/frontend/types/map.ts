import type { MapOptions } from 'maplibre-gl'
import type { MapControlsOptions } from '@/composables/useMapInstance'
import type { BoundsUrl } from '@/composables/useMapBoundingBox'

// A selectable base tile layer (see `constants/map.ts`'s BASELAYERS_DEFAULT for the
// two the app ships with).
export interface MapBaselayer {
  id: string
  name: string
  style: string
}

// One entry of MapHelper::ALL_SERVICES_FOR_POINT_QUERY, passed as `servicesForPointQuery`
// to `Map` (`turbo_mount "Map"`) and consumed by useMapPopups' click-query flow.
export interface PointQueryService {
  url: string
  isPoint?: boolean
  queryString?: string
}

// Field labels for a queried point-feature's popup — passed as `popupAttributes` to
// `Map`. See useMapPopups' attributeHtml/generateHtml.
export interface PopupAttributeLabels {
  name: string
  site_id: string
  site_pid: string
}

// Shape of `MapBaseProps['options']` / `MapProps['options']` — see
// app/frontend/constants/map.ts for the defaults each key falls back to.
export interface MapOptionsPayload {
  map?: Partial<MapOptions> & { boundsUrl?: BoundsUrl }
  controls?: Partial<MapControlsOptions>
  baselayers?: MapBaselayer[]
}
