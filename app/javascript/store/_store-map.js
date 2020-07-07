import { pushIfUniqueId, spliceByObjectId } from '../helpers/array-helpers'

export const storeMap = {
  namespaced: true,

  state: {
    visibleOverlays: [],
    visibleLayers: [],
  },

  actions: {
    addOverlay ({ commit }, overlay) {
      commit('addOverlay', overlay)
      overlay.layers.forEach(l => commit('addLayer', l))
    },

    removeOverlay ({ commit }, overlay) {
      commit('removeOverlay', overlay)
      overlay.layers.forEach(l => commit('removeLayer', l))
    }
  },

  mutations: {
    addOverlay (state, overlay) {
      pushIfUniqueId(state.visibleOverlays, overlay)
    },

    removeOverlay (state, overlayId) {
      spliceByObjectId(state.visibleOverlays, overlayId)
    },
    
    addLayer (state, layer) {
      pushIfUniqueId(state.visibleLayers, layer)
    },

    removeLayer (state, layerId) {
      spliceByObjectId(state.visibleLayers, layerId)
    }
  },
}
