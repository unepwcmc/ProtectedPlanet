// Vue3/MapLibre port of app/javascript/components/map/mixins/mixin-controls.js
// and the mapboxgl.Map setup previously inlined in VMap.vue.
import { ref, type Ref } from 'vue'
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
// Base positioning CSS for controls/popups/markers (.maplibregl-ctrl, .maplibregl-popup,
// ...). The legacy Vue2 map gets the mapbox-gl equivalent from a CDN <link> in
// _head.html.erb; this island needs its own since it's a different library/prefix
// (.maplibregl-* not .mapboxgl-*) never pulled in via npm before.
import 'maplibre-gl/dist/maplibre-gl.css'

export interface MapControlsOptions {
  showZoom: boolean
  showCompass: boolean
  showBaselayerControls: boolean
  attributionLocation: 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'
}

let rtlPluginRegistered = false

export function useMapInstance() {
  const { VITE_MAPBOX_TOKEN: accessToken } = useEnvs()
  const map = ref<MapLibreMap | null>(null) as Ref<MapLibreMap | null>

  function addControls(controlsOptions: MapControlsOptions) {
    if (!map.value) return

    if (controlsOptions.showZoom) {
      map.value.addControl(new NavigationControl({ showCompass: controlsOptions.showCompass }))
    }

    map.value.addControl(new AttributionControl(), controlsOptions.attributionLocation)
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
