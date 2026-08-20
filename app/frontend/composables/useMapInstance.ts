import { ref } from 'vue'
import {
  Map as MapLibreMap,
  AttributionControl,
  NavigationControl,
  setRTLTextPlugin,
  type MapOptions,
  type MapMouseEvent
} from 'maplibre-gl'
import { isMapboxURL, transformMapboxUrl } from 'maplibregl-mapbox-request-transformer'
import { RTL_TEXT_PLUGIN_URL } from '@/constants/map'
import useEnvs from '@/composables/useEnvs'
import 'maplibre-gl/dist/maplibre-gl.css'

export interface MapControlsOptions {
  showZoom: boolean
  showCompass: boolean
  showBaselayerControls: boolean
  attributionLocation: 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'
}

let rtlPluginRegistered = false

export default function () {
  const { VITE_MAPBOX_TOKEN: accessToken } = useEnvs()
  const map = ref<MapLibreMap | null>(null)

  function addControls(controlsOptions: MapControlsOptions) {
    if (!map.value) return

    if (controlsOptions.showZoom) {
      map.value.addControl(new NavigationControl({ showCompass: controlsOptions.showCompass }))
    }

    map.value.addControl(new AttributionControl({ compact: true }), controlsOptions.attributionLocation)
  }

  function initMap(
    mapOptions: MapOptions,
    controlsOptions: MapControlsOptions,
    onClick?: (e: MapMouseEvent) => void,
    onStyleLoad?: () => void
  ) {
    if (!rtlPluginRegistered) {
      rtlPluginRegistered = true
      setRTLTextPlugin(RTL_TEXT_PLUGIN_URL, true) // lazy-loaded
    }

    map.value = new MapLibreMap({
      ...mapOptions,
      // Without this, WebGL discards its drawing buffer after each frame -
      // fine for normal interactive use, but the PDF export (rasterize.js)
      // captures the page well after the map's last render call (once
      // 'idle' fires), by which point the buffer would otherwise already be
      // cleared, producing a blank map in the exported PDF. Must be nested
      // under canvasContextAttributes, not a top-level MapOptions key - this
      // library moved WebGL context attributes here and silently ignores a
      // top-level preserveDrawingBuffer.
      canvasContextAttributes: { preserveDrawingBuffer: true },
      transformRequest: (url, resourceType) =>
        isMapboxURL(url) ? transformMapboxUrl(url, resourceType, accessToken) : undefined
    })

    addControls(controlsOptions)

    map.value.on('style.load', () => {
      onStyleLoad?.()
    })

    if (onClick) {
      map.value.on('click', (e) => {
        if (e.originalEvent.detail === 1) onClick(e)
      })
    }
  }

  return { map, initMap, addControls }
}
