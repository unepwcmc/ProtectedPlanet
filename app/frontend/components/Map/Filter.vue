<template>
  <div
    class="v-map-filter"
    :class="{ 'v-map-filter--toggleable': isToggleable }"
    @click.stop="onClick"
  >
    <div
      class="v-map-filter__color"
      :style="{ backgroundColor: color }"
    />
    <span
      class="v-map-filter__description"
      v-text="title"
    />
    <div
      v-if="isToggleable"
      class="v-map-filter__active-toggler"
    >
      <MapToggler
        :gaId="id"
        :active="isShown"
        @change="setShown"
      />
    </div>
  </div>
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
