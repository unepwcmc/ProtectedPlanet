<template>
  <li
    class="ct-map-overlay"
    :class="{ 'ct-map-overlay--toggleable': isToggleable }"
    @click.stop="onClick"
  >
    <div
      class="ct-map-overlay__color"
      :style="{ backgroundColor: color }"
    />
    <span
      class="ct-map-overlay__description"
      v-text="title"
    />
    <div
      v-if="isToggleable"
      class="ct-map-overlay__active-toggler"
    >
      <MapToggler
        :gaId="id"
        :active="isShown"
        @change="setShown"
      />
    </div>
  </li>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import MapToggler from '@/components/Map/Toggler.vue'
import { useMapStore, type MapOverlay } from '@/stores/useMapStore'
import type { MapFilterProps } from '@/types/backend'

type MapFilter = MapFilterProps
const props = withDefaults(defineProps<MapFilter>(), {
  color: '#cccccc',
  isShownByDefault: true,
  isToggleable: true
})

const mapStore = useMapStore()

const overlayForStore = computed<MapOverlay>(() => ({ layers: props.layers, id: props.id }))

const isShown = computed(() => mapStore.visibleOverlays.some(o => o.id === props.id))

function setShown(shown: boolean) {
  if (shown) {
    mapStore.addOverlay(overlayForStore.value)
  }
  else {
    mapStore.removeOverlay(overlayForStore.value)
  }
}

function onClick() {
  if (props.isToggleable) {
    setShown(!isShown.value)
  }
}

onMounted(() => {
  setShown(props.isShownByDefault)
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-map-overlay {
  @apply
  tw-shared-base-flex-gap-3
  items-center;
}

.ct-map-overlay--toggleable {
  @apply cursor-pointer;
}

.ct-map-overlay__color {
  @apply
  size-4.75
  rounded-full
  border
  border-white
  bg-theme-grey
  shrink-0;
}

.ct-map-overlay__description {
  @apply tw-shared-font-hind-siliguri__normal-sm-lg-base-white;
}

</style>
