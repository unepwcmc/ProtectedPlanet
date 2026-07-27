<template>
  <div class="v-map-baselayer-controls">
    <button
      v-for="layer in baselayers"
      :key="`baselayer-toggle-${layer.id}`"
      class="v-map-baselayer-controls__control"
      :class="{ selected: layer.id === mapStore.selectedBaselayer.id }"
      @click="selectBaselayer(layer)"
    >
      <span v-text="layer.name" />
    </button>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useMapStore } from '@/stores/useMapStore'
import type { MapBaselayer } from '@/types/map'

const props = defineProps<{
  baselayers: MapBaselayer[]
}>()

const mapStore = useMapStore()

onMounted(() => {
  mapStore.updateSelectedBaselayer(props.baselayers[0])
})

const selectBaselayer = (layer: MapBaselayer) => mapStore.updateSelectedBaselayer(layer)
</script>
