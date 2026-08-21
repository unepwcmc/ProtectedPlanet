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
// Module scope, shared by every instance — see containerId below.
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

// A hardcoded id would collide with a second Map on the page: getElementById
// returns the first match, mounting this canvas into another's container. The
// counter must stay at module scope — `<script setup>` re-runs per instance.
const containerId = `${MAP_OPTIONS_DEFAULT.container}-${mapInstanceCount++}`
const { visibleLayers } = useMapOverlays()

// Holds the PDF rasterizer's readiness flag open until tiles have loaded
// (MapLibre 'idle', below). Registered outside onMounted so there is no gap
// between mount and reporting busy — see pdfReady.ts.
const markMapRenderDone = registerPendingRender()

const baselayers = computed(() => props.options.baselayers ?? BASELAYERS_DEFAULT)
// The map is built with the first baselayer's style, so selection starts there.
const selectedBaselayer = ref<MapBaselayer>(baselayers.value[0])
const controlsOptions = computed(() => ({ ...CONTROLS_OPTIONS_DEFAULT, ...props.options.controls }))

const { map, initMap } = useMapInstance()
const { executeAfterStyleLoad, setFirstForegroundLayerId, showLayers, hideLayers } = useMapLayers(map)
const { onClick: onPopupClick, addPopup, popupAttributes, generateAttributesHtml } = useMapPopups(map, props.servicesForPointQuery, props.popupAttributes)
// PA-search "jump to result and open its popup", using the same markup as the
// click-to-query popup. A search result only carries name + id (+ site_pid),
// not the full feature attribute set, so those come from the autocomplete
// result rather than a second lookup.
const { initBounds, initBoundingBoxAndMap, zoomTo } = useMapBoundingBox(map, (coords, options) => {
  if (!options.name) return

  addPopup(coords, generateAttributesHtml([
    { title: popupAttributes.name, value: options.name, url: options.is_pa ? `/${options.id}` : undefined },
    { title: popupAttributes.site_id, value: options.is_pa ? String(options.id) : undefined },
    { title: popupAttributes.site_pid, value: (options.site_pid as string | null) ?? undefined }
  ]))
})

const mapOptions = computed<MapOptions>(() => {
  // boundsUrl isn't a MapLibre option; initBoundingBoxAndMap consumes it first.
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
      // Mapbox Studio style JSON carries a `projection.name` MapLibre rejects;
      // this is the transformer package's recommended per-swap fix.
      map.value!.setStyle(layer.style!, {
        // `_previousStyle` is required by the package's type but unused by its
        // implementation; the adapter just satisfies MapLibre's signature.
        transformStyle: (previous: StyleSpecification | undefined,
          next: StyleSpecification) =>
          transformMapboxStyle(previous ?? next, next)
      })
      showLayers(visibleLayers.value)
    })
  }
)

const resize = () => map.value?.resize()

// A map mounted inside a hidden tab (e.g. wdpca/Green List tab extras)
// initialises at 0×0, so MapLibre needs an explicit resize() once the container
// has a layout box. Container-driven, so it isn't coupled to the Tabs component.
let visibilityObserver: IntersectionObserver | undefined
const mapContainer = useTemplateRef('mapContainer')

onMounted(() => {
  initBoundingBoxAndMap(props.options.map?.boundsUrl, () => {
    try {
      // Sync the new instance to whatever is already registered. The watcher
      // above only fires on changes, and map creation waits on the bounds
      // fetch, so children usually register their overlays before a map exists.
      initMap(mapOptions.value, controlsOptions.value, onPopupClick, () => {
        setFirstForegroundLayerId()
        showLayers(visibleLayers.value)
      })
    }
    catch (error) {
      // A failed map must not hold the readiness flag open, or the rasterizer
      // waits out its whole budget for an 'idle' that can never fire and that
      // page's PDF can never be generated. Print the rest without a map.
      console.error('Map failed to initialise; continuing without it', error)
      markMapRenderDone()
      return
    }

    // Same reasoning: the listeners below are optional-chained off map.value,
    // so a null map would register nothing and hang the wait.
    if (!map.value) {
      console.error('Map initialised without an instance; continuing without it')
      markMapRenderDone()
      return
    }
    // The first 'idle' only covers the base style — useMapLayers adds overlays
    // asynchronously, so they can still be in flight. Keep listening across
    // idle cycles until every expected layer is in the style; idle then means
    // zero outstanding requests map-wide, so their tiles are loaded too.
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
