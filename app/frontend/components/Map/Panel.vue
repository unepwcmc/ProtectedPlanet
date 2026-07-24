<template>
  <div
    ref="root"
    class="v-map-filters"
    :class="{ 'v-map-filters--hidden': isHidden }"
  >
    <MapHeader
      :title
      :filtersShown="show"
      closeable
      @toggle="show = !show"
    />
    <div
      v-show="show"
      class="v-map-filters__body"
    >
      <slot name="top" />
      <slot />
      <div class="v-map-filters__overlays">
        <div
          v-for="(overlay, index) in overlays"
          :key="index"
          class="v-map-filters__overlay"
        >
          <MapFilter v-bind="overlay" />
        </div>
      </div>
      <MapDisclaimer :disclaimer />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import MapHeader from '@/components/Map/Header.vue'
import MapFilter from '@/components/Map/Filter.vue'
import MapDisclaimer from '@/components/Map/Disclaimer.vue'
import type { MapPanelProps } from '@/types/backend'
import { PANEL_DISABLED_TAB_INDEX, PANEL_FOCUSABLE_SELECTOR } from '@/constants/map'

type MapPanel = MapPanelProps
const props = withDefaults(defineProps<MapPanel>(), {
  isHidden: false,
  disclaimer: null
})

const show = ref(true)
const root = ref<HTMLElement | null>(null)

onMounted(() => {
  if (props.isHidden && root.value) {
    root.value.querySelectorAll<HTMLElement>(PANEL_FOCUSABLE_SELECTOR).forEach((el) => {
      el.tabIndex = PANEL_DISABLED_TAB_INDEX
    })
  }
})
</script>
