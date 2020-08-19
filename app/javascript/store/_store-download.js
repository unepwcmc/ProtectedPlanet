export const storeDownload = {
  namespaced: true,

  state: {
    downloadItems: [],
    isModalActive: false
  },

  actions: {
    addNewDownloadItem ({ commit }, item) {
      commit('addNewDownloadItem', item)
      commit('updateLocalStorage')
    },

    deleteDownloadItem ({ commit }, item) {
      commit('deleteDownloaditem', item)
      commit('updateLocalStorage')
    },

    initialiseStore ({ commit }) {
      console.log('initialise', localStorage.getItem('downloadItems'))
      if (localStorage.hasOwnProperty('downloadItems')) {
        commit('initialiseDownloadItems', JSON.parse(localStorage.getItem('downloadItems')))
      }
    },

    toggleDownloadModal ({ commit }, boolean) {
      boolean ? commit('showDownloadModal') : commit('hideDownloadModal')
    }
  },

  mutations: {
    addNewDownloadItem (state, item) {
      state.downloadItems.push(item)
    },

    deleteDownloaditem (state, item) {
      state.downloadItems = state.downloadItems.filter(download => download.id != item.id )
    },

    hideDownloadModal (state) {
      state.isModalActive = false
    },

    initialiseDownloadItems (state, downloadItems) {
      state.downloadItems = downloadItems
    },

    showDownloadModal (state) {
      state.isModalActive = true
    },

    updateLocalStorage (state) {
      localStorage.setItem('downloadItems', JSON.stringify(state.downloadItems))
    }
  }
}