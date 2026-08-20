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
import { onBeforeMount, useTemplateRef } from 'vue'
import MapHeader from '@/components/Map/Header.vue'
import MapBase from '@/components/Map/Base.vue'
import MapDisclaimer from '@/components/Map/Disclaimer.vue'
import MapPanel from '@/components/Map/Panel.vue'
import type { MapProps } from '@/types/backend'
import type { ZoomToOptions } from '@/composables/useMapBoundingBox'
import { useMapStore } from '@/stores/useMapStore'

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

const mapStore = useMapStore()

// onBeforeMount, not onMounted: a parent's beforeMount runs BEFORE any child
// mounts, whereas its mounted runs AFTER them -- clearing in onMounted would wipe
// the overlays this page's own Overlay.vue children just registered.
onBeforeMount(() => mapStore.reset())

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
