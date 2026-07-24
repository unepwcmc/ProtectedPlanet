<template>
  <div class="v-map">
    <div
      :id="containerId"
      class="map__mapbox"
    />
    <MapBaselayerControls
      v-if="controlsOptions.showBaselayerControls"
      :baselayers
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import MapBaselayerControls from '@/components/Map/BaselayerControls.vue'
import { useMapStore } from '@/stores/useMapStore'
import { useMapInstance } from '@/composables/useMapInstance'
import { useMapLayers } from '@/composables/useMapLayers'
import { useMapBoundingBox } from '@/composables/useMapBoundingBox'
import { useMapPopups } from '@/composables/useMapPopups'
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
const { onClick: onPopupClick } = useMapPopups(map, props.servicesForPointQuery, props.popupAttributes)
// PA-search "jump to result + open its popup" flow (mixin-bounding-box's
// addPopupFromExtent) is wired up in Wave 7 once VMapPASearch/Autocomplete land.
const { initBounds, initBoundingBoxAndMap, zoomTo } = useMapBoundingBox(map)

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

onMounted(() => {
  initBoundingBoxAndMap(props.options.map?.boundsUrl, () => {
    initMap(mapOptions.value, controlsOptions.value, onPopupClick, setFirstForegroundLayerId)
  })
})

defineExpose({ zoomTo, resize: () => map.value?.resize() })
</script>
