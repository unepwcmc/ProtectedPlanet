export const storeDownload = {
  namespaced: true,

  state: {
    downloadItems: []
  },

  actions: {
    addNewDownloadItem ({ commit }, item) {
      commit('addNewDownloadItem', item)
    }
  },

  mutations: {
    addNewDownloadItem (state, item) {
      state.downloadItems.push(item)
    }
  }
}