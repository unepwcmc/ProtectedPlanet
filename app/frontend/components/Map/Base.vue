<template>
  <div class="ct-map-base">
    <div
      :id="containerId"
      ref="mapContainer"
      class="ct-map-base__canvas"
    />
    <MapBaselayerControls
      v-if="controlsOptions.showBaselayerControls"
      :baselayers
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, useTemplateRef, watch } from 'vue'
import MapBaselayerControls from '@/components/Map/BaselayerControls.vue'
import { useMapStore } from '@/stores/useMapStore'
import useMapInstance from '@/composables/useMapInstance'
import useMapLayers from '@/composables/useMapLayers'
import useMapBoundingBox from '@/composables/useMapBoundingBox'
import useMapPopups from '@/composables/useMapPopups'
import { BASELAYERS_DEFAULT, CONTROLS_OPTIONS_DEFAULT, MAP_OPTIONS_DEFAULT } from '@/constants/map'
import { transformMapboxStyle } from 'maplibregl-mapbox-request-transformer'
import type { MapOptions, StyleSpecification } from 'maplibre-gl'
import type { MapBaseProps } from '@/types/backend'

type MapBase = MapBaseProps
const props = withDefaults(defineProps<MapBase>(), {
  options: () => ({}),
  servicesForPointQuery: () => [],
  popupAttributes: undefined
})

// A hardcoded id would collide if more than one Map instance (or the still-live
// legacy `v-map`) is on the same page — getElementById returns the first match,
// silently mounting this instance's canvas into someone else's container.
let mapInstanceCount = 0
const containerId = `${MAP_OPTIONS_DEFAULT.container}-${mapInstanceCount++}`
const mapStore = useMapStore()

const baselayers = computed(() => props.options.baselayers ?? BASELAYERS_DEFAULT)
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
    style: baselayers.value[0].style
  }

  if (initBounds.value) opts.bounds = initBounds.value

  return opts
})

watch(
  () => mapStore.visibleLayers,
  (newLayers, oldLayers) => {
    const layersToHide = oldLayers.filter(oL => !newLayers.some(nL => nL.id === oL.id))
    hideLayers(layersToHide)
    showLayers(newLayers)
  }
)

watch(
  () => mapStore.selectedBaselayer,
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
      showLayers(mapStore.visibleLayers)
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
    // The pinia store is an app-wide singleton and SURVIVES Turbo Drive navigation
    // (only the body is swapped, the JS context persists), while this map island is
    // torn down and rebuilt. addOverlay is idempotent, so on a second visit to a map
    // page the overlay is already in the store, visibleLayers never changes, the
    // watcher above never fires, and this brand new map never gets its layers --
    // which is why the highlighted area vanished from every map after the first.
    // Sync the new instance to whatever the store already holds, once the style is
    // ready to accept layers.
    initMap(mapOptions.value, controlsOptions.value, onPopupClick, () => {
      setFirstForegroundLayerId()
      showLayers(mapStore.visibleLayers)
    })

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
