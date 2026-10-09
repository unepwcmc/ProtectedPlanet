import { shallowRef } from 'vue'
import {
  Map as MapLibreMap,
  AttributionControl,
  NavigationControl,
  ScaleControl,
  setRTLTextPlugin,
  setWorkerUrl,
  type MapOptions,
  type MapMouseEvent
} from 'maplibre-gl'
// MapLibre builds its tile worker's URL from a template literal
// (`new URL(`./${t}`, import.meta.url)`), which Vite cannot statically analyse,
// so the worker was never emitted and 404'd in the build. Tiles are fetched
// only by the worker, so the map rendered its background layer and nothing
// else, with no console error. `?worker&url` makes Vite bundle it (along with
// its own maplibre-gl-shared.mjs import) and return the hashed URL.
import maplibreWorkerUrl from 'maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url'
import { isMapboxURL, transformMapboxUrl } from 'maplibregl-mapbox-request-transformer'
import { RTL_TEXT_PLUGIN_URL } from '@/constants/map'
import useEnvs from '@/composables/useEnvs'
import 'maplibre-gl/dist/maplibre-gl.css'

export interface MapControlsOptions {
  showZoom: boolean
  showCompass: boolean
  showBaselayerControls: boolean
  showScale: boolean
  scaleUnit: 'metric' | 'imperial'
  scaleMaxWidth: number
  attributionLocation: 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'
}

// Must run before any Map is constructed — MapLibre caches the worker URL.
setWorkerUrl(maplibreWorkerUrl)

let rtlPluginRegistered = false

export default function () {
  const { VITE_MAPBOX_TOKEN: accessToken } = useEnvs()
  // shallowRef, not ref: deep reactivity proxies the whole MapLibre Map,
  // including frozen internals like Color, whose read-only non-configurable
  // `rgb` then breaks the Proxy invariant and throws on read. shallowRef keeps
  // .value assignment reactive without proxying the instance's internals.
  const map = shallowRef<MapLibreMap | null>(null)

  function addControls(controlsOptions: MapControlsOptions) {
    if (!map.value) return

    if (controlsOptions.showZoom) {
      map.value.addControl(new NavigationControl({
        showCompass: controlsOptions.showCompass
      }))
    }

    if (controlsOptions.showScale) {
      map.value.addControl(new ScaleControl({
        maxWidth: controlsOptions.scaleMaxWidth,
        unit: controlsOptions.scaleUnit
      }))
    }

    // No `compact`: MapLibre then collapses the attribution to its own pill below
    // 640px of canvas width and shows the full strip above it. The empty object is
    // required — the constructor's default parameter is `{ compact: true }` plus a
    // MapLibre credit link, so omitting it entirely pins the pill at every width.
    map.value.addControl(new AttributionControl({}), controlsOptions.attributionLocation)
    collapseCompactAttribution()
    // It re-expands the pill every time a resize crosses that width.
    map.value.on('resize', collapseCompactAttribution)
  }

  // MapLibre adds the compact pill pre-expanded and only collapses it on the
  // first pan, so mirror its own collapse — drop `compact-show`, leave the
  // details element open — to have small maps start compact.
  function collapseCompactAttribution() {
    map.value?.getContainer()
      .querySelector('.maplibregl-ctrl-attrib.maplibregl-compact')
      ?.classList.remove('maplibregl-compact-show')
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
      // WebGL otherwise discards its drawing buffer after each frame, and the
      // PDF export captures the page after the last render, so the map comes
      // out blank. Must be nested here, not a top-level MapOptions key —
      // MapLibre silently ignores a top-level preserveDrawingBuffer.
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
