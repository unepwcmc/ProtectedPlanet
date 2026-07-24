<template>
  <div class="map--main">
    <MapHeader
      v-if="showHeader"
      :title
    />
    <MapBase
      :options
      :servicesForPointQuery
      :popupAttributes
    />
    <MapPanel
      :title
      :overlays
      :isHidden
      :disclaimer
    />
  </div>
</template>

<script setup lang="ts">
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
  showHeader: true
})
</script>
