// Vue3/MapLibre port of app/javascript/components/map/mixins/mixin-controls.js
// and the mapboxgl.Map setup previously inlined in VMap.vue.
import { shallowRef, type Ref } from 'vue'
import {
  Map as MapLibreMap,
  AttributionControl,
  NavigationControl,
  setRTLTextPlugin,
  setWorkerUrl,
  type MapOptions,
  type MapMouseEvent
} from 'maplibre-gl'
// MapLibre fetches every vector tile from a Web Worker, and it derives that
// worker's URL at runtime:
//
//   const t = url.endsWith('-dev.mjs') ? 'maplibre-gl-worker-dev.mjs' : 'maplibre-gl-worker.mjs'
//   return new URL(`./${t}`, import.meta.url).href
//
// That is a TEMPLATE LITERAL, so Vite cannot statically analyse it and never emits
// the worker as an asset. In the built bundle the request resolved to
// /vite/assets/maplibre-gl-worker.mjs -> 404, the worker never started, and the map
// rendered its style's background layer and nothing else: style, sprites and
// TileJSON all load on the MAIN thread (all 200), while tile requests -- which only
// the worker makes -- never happened at all. No console error, correct canvas size,
// valid bounds; just an empty map.
//
// `?worker&url` makes Vite bundle the worker (resolving its own
// `./maplibre-gl-shared.mjs` import, which is equally absent from the build) and
// hand back the hashed URL of the emitted file.
import maplibreWorkerUrl from 'maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url'
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

// Must run before any Map is constructed -- MapLibre resolves the worker URL once
// and caches it.
setWorkerUrl(maplibreWorkerUrl)

let rtlPluginRegistered = false

export default function () {
  const { VITE_MAPBOX_TOKEN: accessToken } = useEnvs()
  // shallowRef, NOT ref. ref() makes the assigned value deeply reactive, so the
  // whole MapLibre Map -- including internal frozen objects like Color, whose `rgb`
  // is a read-only non-configurable property -- gets wrapped in a Proxy. Reading it
  // then violates the Proxy invariant and throws:
  //
  //   TypeError: 'get' on proxy: property 'rgb' is a read-only and non-configurable
  //   data property on the proxy target but the proxy did not return its actual
  //   value (expected '[object Array]' but got '[object Object]')
  //
  // shallowRef keeps .value assignment reactive (watchers and templates still fire)
  // without proxying the instance's internals. The `as Ref<...>` cast this line used
  // to carry was a symptom of the same problem.
  const map = shallowRef<MapLibreMap | null>(null) as Ref<MapLibreMap | null>

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
