// Vue3/Pinia port of the legacy Vuex `map` module (app/javascript/store/_store-map.js)
import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { MapBaselayer } from '@/types/map'
import type { MapLayer } from '@/composables/useMapLayers'

export interface MapOverlay {
  id: string
  layers: MapLayer[]
}

export const useMapStore = defineStore('map', () => {
  const visibleOverlays = ref<MapOverlay[]>([])
  const visibleLayers = ref<MapLayer[]>([])
  const selectedBaselayer = ref<Partial<MapBaselayer>>({})

  function addOverlay(overlay: MapOverlay) {
    if (!visibleOverlays.value.some(o => o.id === overlay.id)) {
      visibleOverlays.value = [...visibleOverlays.value, overlay]
    }
    overlay.layers.forEach((layer) => {
      if (!visibleLayers.value.some(l => l.id === layer.id)) {
        visibleLayers.value = [...visibleLayers.value, layer]
      }
    })
  }

  function removeOverlay(overlay: MapOverlay) {
    visibleOverlays.value = visibleOverlays.value.filter(o => o.id !== overlay.id)
    overlay.layers.forEach((layer) => {
      visibleLayers.value = visibleLayers.value.filter(l => l.id !== layer.id)
    })
  }

  function updateSelectedBaselayer(layer: MapBaselayer) {
    selectedBaselayer.value = layer
  }

  return { visibleOverlays, visibleLayers, selectedBaselayer, addOverlay, removeOverlay, updateSelectedBaselayer }
})
