<template>
  <div class="ct-map">
    <MapHeader
      v-if="showHeader"
      class="ct-map__header"
      :title
    />
    <MapBase
      ref="mapBaseRef"
      :options
      :servicesForPointQuery
      :popupAttributes
    />
    <MapDisclaimer
      v-if="isHidden"
      :disclaimer
      :mapiIsForRegionCountryPA
    />
    <MapPanel
      :title
      :overlays
      :isHidden
      :disclaimer
      :type
      :autocompleteErrorMessages
      :autocompletePlaceholder
      :mapiIsForRegionCountryPA
      @zoomTo="onZoomTo"
    />
  </div>
</template>

<script setup lang="ts">
import { useTemplateRef } from 'vue'
import MapHeader from '@/components/Map/Header.vue'
import MapBase from '@/components/Map/Base.vue'
import MapDisclaimer from '@/components/Map/Disclaimer.vue'
import MapPanel from '@/components/Map/Panel.vue'
import type { MapProps } from '@/types/backend'
import type { ZoomToOptions } from '@/composables/useMapBoundingBox'
import { provideMapOverlays } from '@/composables/useMapOverlays'

type Map = MapProps
withDefaults(defineProps<Map>(), {
  options: () => ({}),
  servicesForPointQuery: () => [],
  popupAttributes: undefined,
  disclaimer: null,
  isHidden: false,
  showHeader: true,
  type: undefined,
  autocompleteErrorMessages: undefined,
  autocompletePlaceholder: undefined,
  mapiIsForRegionCountryPA: false
})

// Owns the overlay state shared by MapBase (which draws the layers) and the
// MapPanel > MapOverlay children (which toggle them). Scoped to this tree, so a
// fresh mount starts empty rather than inheriting the previous map's overlays.
provideMapOverlays()

const mapBaseRef = useTemplateRef('mapBaseRef')

const onZoomTo = (options: ZoomToOptions) => mapBaseRef.value?.zoomTo(options)
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-map {
  @apply md:relative;
}

.ct-map__header {
  @apply flex md:hidden;
}
</style>
