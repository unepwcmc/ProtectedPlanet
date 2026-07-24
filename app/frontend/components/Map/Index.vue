<template>
  <div class="map--main">
    <MapHeader
      v-if="showHeader"
      :title
    />
    <MapBase
      ref="mapBaseRef"
      :options
      :servicesForPointQuery
      :popupAttributes
    />
    <MapPanel
      :title
      :overlays
      :isHidden
      :disclaimer
      :type
      :autocompleteErrorMessages
      :autocompletePlaceholder
      @zoomTo="mapBaseRef?.zoomTo($event)"
    />
  </div>
</template>

<script setup lang="ts">
import { useTemplateRef } from 'vue'
import MapHeader from '@/components/Map/Header.vue'
import MapBase from '@/components/Map/Base.vue'
import MapPanel from '@/components/Map/Panel.vue'
import type { MapProps } from '@/types/backend'

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
  autocompletePlaceholder: undefined
})

const mapBaseRef = useTemplateRef('mapBaseRef')
</script>
<style lang="css" scoped>
.map--main{
  @apply w-full;
}
</style>
