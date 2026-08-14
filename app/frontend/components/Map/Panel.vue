<template>
  <div
    ref="root"
    class="ct-map-panel"
    :class="{ 'ct-map-panel--hidden': isHidden }"
  >
    <MapHeader
      :title
      :filtersShown="isVisible"
      closeable
      class="ct-map-panel__header"
      @toggle="toggleShow"
    />
    <div
      v-show="isVisible"
      class="ct-map-panel__body"
    >
      <MapPaSearch
        v-if="hasPaSearch"
        :autocompleteErrorMessages="autocompleteErrorMessages!"
        :autocompletePlaceholder="autocompletePlaceholder!"
        :type="type!"
        @zoomTo="onZoomTo"
      />
      <ul class="ct-map-panel__overlays">
        <MapOverlay
          v-for="(overlay, index) in overlays"
          :key="index"
          v-bind="overlay"
        />
      </ul>
      <MapDisclaimer
        :disclaimer
        :mapiIsForRegionCountryPA
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import MapHeader from '@/components/Map/Header.vue'
import MapOverlay from '@/components/Map/Overlay.vue'
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
  autocompletePlaceholder: undefined,
  mapiIsForRegionCountryPA: false
})
const emit = defineEmits<{ zoomTo: [options: ZoomToOptions] }>()

const isVisible = ref(true)
const root = ref<HTMLElement | null>(null)

const toggleShow = () => (isVisible.value = !isVisible.value)
const onZoomTo = (options: ZoomToOptions) => emit('zoomTo', options)

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

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-map-panel {
  @apply
  bg-theme-grey-xdark
  text-theme-grey-light
  md:absolute
  md:z-0
  md:w-85
  md:top-4.25
  md:left-4.5
  lg:w-124
  lg:top-8
  lg:left-10.75;
}

.ct-map-panel--hidden {
  @apply sr-only;
}

.ct-map-panel__header {
  @apply hidden md:flex;
}

.ct-map-panel__body {
  @apply
  tw-shared-base-flex-col-gap-9
  justify-between
  py-7.5
  px-4.5
  md:pt-4.5
  md:px-4.5
  md:pb-10;
}

.ct-map-panel__overlays {
  @apply tw-shared-base-flex-col-gap-3;
}
</style>
