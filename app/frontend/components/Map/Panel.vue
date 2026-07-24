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
      <MapPaSearch
        v-if="hasPaSearch"
        :autocompleteErrorMessages="autocompleteErrorMessages!"
        :autocompletePlaceholder="autocompletePlaceholder!"
        :type="type!"
        @zoomTo="emit('zoomTo', $event)"
      />
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
import { ref, computed, onMounted } from 'vue'
import MapHeader from '@/components/Map/Header.vue'
import MapFilter from '@/components/Map/Filter.vue'
import MapDisclaimer from '@/components/Map/Disclaimer.vue'
import MapPaSearch from '@/components/Map/PaSearch.vue'
import type { MapPanelProps } from '@/types/backend'
import type { ZoomToOptions } from '@/composables/useMapBoundingBox'
import { PANEL_DISABLED_TAB_INDEX, PANEL_FOCUSABLE_SELECTOR } from '@/constants/map'

type MapPanel = MapPanelProps
const props = withDefaults(defineProps<MapPanel>(), {
  isHidden: false,
  disclaimer: null,
  type: undefined,
  autocompleteErrorMessages: undefined,
  autocompletePlaceholder: undefined
})
const emit = defineEmits<{ zoomTo: [options: ZoomToOptions] }>()

const show = ref(true)
const root = ref<HTMLElement | null>(null)

// Matches the legacy `v-if="!areFiltersHidden"` on `<v-map-pa-search>` — the
// header-map layout (PA show, country, region) omits these props entirely
// rather than passing isHidden, so both conditions are checked.
const hasPaSearch = computed(() =>
  !props.isHidden && !!props.type && !!props.autocompleteErrorMessages && !!props.autocompletePlaceholder
)

onMounted(() => {
  if (props.isHidden && root.value) {
    root.value.querySelectorAll<HTMLElement>(PANEL_FOCUSABLE_SELECTOR).forEach((el) => {
      el.tabIndex = PANEL_DISABLED_TAB_INDEX
    })
  }
})
</script>
