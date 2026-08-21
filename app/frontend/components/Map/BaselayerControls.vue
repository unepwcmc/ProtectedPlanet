<template>
  <div class="ct-map-baselayer-controls">
    <button
      v-for="layer in baselayers"
      :key="`baselayer-toggle-${layer.id}`"
      class="ct-map-baselayer-controls__control"
      :class="{ 'ct-map-baselayer-controls__control--selected': layer.id === selected.id }"
      @click="selectBaselayer(layer)"
    >
      <span v-text="layer.name" />
    </button>
  </div>
</template>

<script setup lang="ts">
import type { MapBaselayer } from '@/types/map'

defineProps<{
  baselayers: MapBaselayer[]
}>()

// MapBase owns the selection, since it swaps the MapLibre style; this is only
// the picker, so a v-model is the whole contract between them.
const selected = defineModel<MapBaselayer>({ required: true })

const selectBaselayer = (layer: MapBaselayer) => (selected.value = layer)
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-map-baselayer-controls {
  @apply absolute bottom-2.5 right-2.5 md:bottom-4 lg:right-4;
}

.ct-map-baselayer-controls__control {
  @apply
  min-w-25
  bg-white
  border
  border-theme-grey-dark
  rounded-none
  cursor-pointer
  tw-shared-font-hind-siliguri__light-sm-lg-base-black
  w-20.5
  h-8.75
  md:w-35
  md:h-11.5
  not-last:border-r-0;
}

.ct-map-baselayer-controls__control:focus:first-child,
.ct-map-baselayer-controls__control:focus:last-child {
  @apply rounded-none;
}

.ct-map-baselayer-controls__control--selected {
  @apply bg-theme-grey-dark text-white;
}

.ct-map-baselayer-controls__control:hover:not(.ct-map-baselayer-controls__control--selected) {
  @apply bg-theme-grey-xlight;
}

.ct-map-baselayer-controls__control:active {
  background-color: #dbdbdb;
}
</style>
