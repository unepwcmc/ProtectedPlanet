<template>
  <div class="ct-map-base">
    <div
      :id="containerId"
      ref="mapContainer"
      class="ct-map-base__canvas"
    />
    <MapBaselayerControls
      v-if="controlsOptions.showBaselayerControls"
      v-model="selectedBaselayer"
      :baselayers
    />
  </div>
</template>

<script lang="ts">
// Module scope: shared by every instance of this component (see containerId below).
let mapInstanceCount = 0
</script>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, useTemplateRef, watch } from 'vue'
import MapBaselayerControls from '@/components/Map/BaselayerControls.vue'
import { useMapOverlays } from '@/composables/useMapOverlays'
import useMapInstance from '@/composables/useMapInstance'
import useMapLayers from '@/composables/useMapLayers'
import useMapBoundingBox from '@/composables/useMapBoundingBox'
import useMapPopups from '@/composables/useMapPopups'
import { registerPendingRender } from '@/lib/pdfReady'
import { BASELAYERS_DEFAULT, CONTROLS_OPTIONS_DEFAULT, MAP_OPTIONS_DEFAULT } from '@/constants/map'
import { transformMapboxStyle } from 'maplibregl-mapbox-request-transformer'
import type { MapOptions, StyleSpecification } from 'maplibre-gl'
import type { MapBaseProps } from '@/types/backend'
import type { MapBaselayer } from '@/types/map'

type MapBase = MapBaseProps
const props = withDefaults(defineProps<MapBase>(), {
  options: () => ({}),
  servicesForPointQuery: () => [],
  popupAttributes: undefined
})

// A hardcoded id would collide if more than one Map instance is on the same page —
// getElementById returns the first match, silently mounting this instance's canvas
// into someone else's container. The counter lives at MODULE scope on purpose:
// everything inside `<script setup>` is compiled into `setup()` and so re-runs per
// instance, which would reset it to 0 and hand every map the same id.
const containerId = `${MAP_OPTIONS_DEFAULT.container}-${mapInstanceCount++}`
const { visibleLayers } = useMapOverlays()

// Holds the PDF rasterizer's readiness flag open until the map has actually
// finished loading tiles (MapLibre's 'idle' event, below) - registered here
// rather than inside onMounted so there's no gap between mount and this
// component reporting itself busy. See pdfReady.ts.
const markMapRenderDone = registerPendingRender()

const baselayers = computed(() => props.options.baselayers ?? BASELAYERS_DEFAULT)
// The map is built with the first baselayer's style (see mapOptions), so the selection
// starts there too — the watcher below only has work to do once the user picks another.
const selectedBaselayer = ref<MapBaselayer>(baselayers.value[0])
const controlsOptions = computed(() => ({ ...CONTROLS_OPTIONS_DEFAULT, ...props.options.controls }))

const { map, initMap } = useMapInstance()
const { executeAfterStyleLoad, setFirstForegroundLayerId, showLayers, hideLayers } = useMapLayers(map)
const { onClick: onPopupClick, addPopup, popupAttributes, generateAttributesHtml } = useMapPopups(map, props.servicesForPointQuery, props.popupAttributes)
// PA-search "jump to result + open its popup" flow (mixin-bounding-box's
// addPopupFromExtent), rendered with the same attribute labels/markup as the
// click-to-query popup above (generateAttributesHtml) — a search result only
// ever has a name + id (+ site_pid for a PA), not the full point-query
// feature attribute set, so site_id/site_pid come from the autocomplete
// result itself rather than a second lookup.
const { initBounds, initBoundingBoxAndMap, zoomTo } = useMapBoundingBox(map, (coords, options) => {
  if (!options.name) return

  addPopup(coords, generateAttributesHtml([
    { title: popupAttributes.name, value: options.name, url: options.is_pa ? `/${options.id}` : undefined },
    { title: popupAttributes.site_id, value: options.is_pa ? String(options.id) : undefined },
    { title: popupAttributes.site_pid, value: (options.site_pid as string | null) ?? undefined }
  ]))
})

const mapOptions = computed<MapOptions>(() => {
  // boundsUrl isn't a real MapLibre option — it's consumed by initBoundingBoxAndMap
  // above before this runs — but passing it through as an extra key is harmless.
  const opts: MapOptions = {
    ...MAP_OPTIONS_DEFAULT,
    ...props.options.map,
    container: containerId,
    style: baselayers.value[0].style,
    attributionControl: false,
    maplibreLogo: false
  }

  if (initBounds.value) opts.bounds = initBounds.value

  return opts
})

watch(
  visibleLayers,
  (newLayers, oldLayers) => {
    const layersToHide = oldLayers.filter(oL => !newLayers.some(nL => nL.id === oL.id))
    hideLayers(layersToHide)
    showLayers(newLayers)
  }
)

watch(
  selectedBaselayer,
  (layer) => {
    if (!layer?.style || !map.value) return

    executeAfterStyleLoad(() => {
      // Mapbox Studio style JSON contains a `projection.name` field MapLibre's style
      // spec rejects; the transformer package's recommended fix strips it per-swap.
      map.value!.setStyle(layer.style!, {
        // The package's own type declares `_previousStyle` as required, but the argument is
        // unused by its implementation (only `nextStyle.projection.name` is read/stripped) —
        // this adapter satisfies MapLibre's `previous: StyleSpecification | undefined` signature.
        transformStyle: (previous: StyleSpecification | undefined,
          next: StyleSpecification) =>
          transformMapboxStyle(previous ?? next, next)
      })
      showLayers(visibleLayers.value)
    })
  }
)

const resize = () => map.value?.resize()

// A map mounted inside a `display: none` tab (e.g. the wdpca/Green List tab
// extras — that container starts hidden whenever it isn't the initially
// selected tab) initialises at 0×0; MapLibre needs an explicit resize() once
// its container actually has a layout box. Vue 3 port of the legacy
// TabTarget.vue's `$eventHub.emit('map:resize')` on tab activation, but
// container-driven rather than coupled to that specific component.
let visibilityObserver: IntersectionObserver | undefined
const mapContainer = useTemplateRef('mapContainer')

onMounted(() => {
  initBoundingBoxAndMap(props.options.map?.boundsUrl, () => {
    try {
      // Sync the new instance to whatever is already registered, once the style is
      // ready to accept layers. The watcher above only fires on CHANGES, and map
      // creation is async (it waits on initBoundingBoxAndMap's bounds fetch), so the
      // MapOverlay children usually finish registering this page's overlays well
      // before there is a map to draw them on — nothing would ever add them.
      initMap(mapOptions.value, controlsOptions.value, onPopupClick, () => {
        setFirstForegroundLayerId()
        showLayers(visibleLayers.value)
      })
    }
    catch (error) {
      // A map that fails to build must not hold the PDF readiness flag open: the
      // rasterizer would wait out its whole budget for an 'idle' event that can
      // never fire, fail by timeout with no hint of the cause, and do it again on
      // every retry - so that page's PDF could never be generated at all. Release
      // the flag and let the rest of the page be printed without a map.
      console.error('Map failed to initialise; continuing without it', error)
      markMapRenderDone()
      return
    }

    // Same reasoning: every listener below is optional-chained off map.value, so
    // without this a null map would silently register nothing and hang the wait.
    if (!map.value) {
      console.error('Map initialised without an instance; continuing without it')
      markMapRenderDone()
      return
    }
    // 'idle' fires once the map has settled all tile requests for the current
    // view, but the FIRST idle only covers the base style - overlays from
    // visibleLayers are added asynchronously (useMapLayers polls for
    // style-load/foreground-layer readiness before calling addLayer), so they
    // can still be mid-flight at that point. Keep listening across idle
    // cycles until every currently-expected layer has actually been added to
    // the style; idle firing at that point guarantees its tiles are loaded
    // too, since idle means zero outstanding requests map-wide.
    const onIdle = () => {
      const allLayersReady = visibleLayers.value.every(layer => map.value?.getLayer(layer.id))
      if (!allLayersReady) return

      map.value?.off('idle', onIdle)
      markMapRenderDone()
    }
    map.value?.on('idle', onIdle)

    if (!mapContainer.value || typeof IntersectionObserver === 'undefined') return

    visibilityObserver = new IntersectionObserver((entries) => {
      if (entries[0]?.isIntersecting) resize()
    })
    visibilityObserver.observe(mapContainer.value)
  })
})

onUnmounted(() => visibilityObserver?.disconnect())

defineExpose({ zoomTo, resize })
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-map-base {
  @apply
  relative
  w-full;
}

.ct-map-base__canvas {
  @apply
  relative
  h-90
  md:h-175;
}
</style>
