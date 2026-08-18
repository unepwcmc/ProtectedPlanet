// Vue3/MapLibre port of app/javascript/components/map/default-options.js
import type { Offset } from 'maplibre-gl'
import type { MapBaselayer } from '@/types/map'

export const BASELAYERS_DEFAULT: MapBaselayer[] = [
  {
    id: 'terrain',
    name: 'Terrain',
    style: 'mapbox://styles/unepwcmc/cko1hsfi50vog17l697cr4d6p'
  },
  {
    id: 'satellite',
    name: 'Satellite',
    style: 'mapbox://styles/unepwcmc/ckniq2twg0q3b17s5gqfxhagf'
  }
]

// Same plugin the legacy Mapbox GL build used — MapLibre's setRTLTextPlugin has an
// identical signature and the plugin build itself is GL-implementation agnostic.
export const RTL_TEXT_PLUGIN_URL
  = 'https://api.mapbox.com/mapbox-gl-js/plugins/mapbox-gl-rtl-text/v0.2.3/mapbox-gl-rtl-text.js'

export const MAP_OPTIONS_DEFAULT = {
  container: 'map-target',
  scrollZoom: false,
  attributionControl: false as const,
  preserveDrawingBuffer: true, // needed for PDF rendering
  zoom: 1.3,
  maxZoom: 10 // Maximum zoom where tiles are cached for the web-map service
}

export const CONTROLS_OPTIONS_DEFAULT = {
  showZoom: true,
  showCompass: false,
  showBaselayerControls: true,
  attributionLocation: 'bottom-left' as const
}

// Hidden-but-not-display:none (screen-reader-only) panels stay in the tab order
// unless focusable descendants are explicitly pulled out of it.
export const PANEL_DISABLED_TAB_INDEX = -5
export const PANEL_FOCUSABLE_SELECTOR = 'select, input, textarea, button, a, [tabindex]:not([tabindex="-1"])'

const POPUP_MARKER_HEIGHT = 18
const POPUP_MARKER_HALF_WIDTH = 7

export const POPUP_OFFSETS: Offset = {
  'center': [0, 0],
  'top': [0, 1],
  'top-left': [0, 1],
  'top-right': [0, 1],
  'bottom': [0, -POPUP_MARKER_HEIGHT - 20],
  'bottom-left': [0, -POPUP_MARKER_HEIGHT - 1],
  'bottom-right': [0, -POPUP_MARKER_HEIGHT - 1],
  'left': [POPUP_MARKER_HALF_WIDTH + 1, -POPUP_MARKER_HEIGHT / 2],
  'right': [-POPUP_MARKER_HALF_WIDTH - 1, -POPUP_MARKER_HEIGHT / 2]
}
