import { addObjectToArrayIfAbsent } from '../helpers/array-helpers'

export const storeMap = {
  namespaced: true,

  state: {
    visibleOverlays: [],
    visibleLayers: [],
    selectedBaselayer: {}
  },

  actions: {
    addOverlay ({ commit }, overlay) {
      commit('addOverlay', overlay)
      overlay.layers.forEach(l => commit('addLayer', l))
    },

    removeOverlay ({ commit }, overlay) {
      commit('removeOverlay', overlay)
      overlay.layers.forEach(l => commit('removeLayer', l))
    },

    updateSelectedBaselayer ({ commit }, layer) {
      commit('updateSelectedBaselayer', layer)
    }
  },

  mutations: {
    addOverlay (state, overlay) {
      state.visibleOverlays = addObjectToArrayIfAbsent(state.visibleOverlays, overlay)
    },

    removeOverlay (state, overlay) {
      state.visibleOverlays = state.visibleOverlays.filter( x => x.id !== overlay.id)
    },
    
    addLayer (state, layer) {
      state.visibleLayers = addObjectToArrayIfAbsent(state.visibleLayers, layer)
    },

    removeLayer (state, layer) {
      state.visibleLayers = state.visibleLayers.filter( x => x.id !== layer.id)
    },

    updateSelectedBaselayer (state, layer) {
      state.selectedBaselayer = layer
    }
  },
}
