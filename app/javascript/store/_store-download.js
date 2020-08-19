export const storeDownload = {
  namespaced: true,

  state: {
    downloadItems: [],
    isModalActive: false,
    isModalMinimised: false
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
      if (localStorage.hasOwnProperty('downloadItems')) {
        commit('initialiseDownloadItems', JSON.parse(localStorage.getItem('downloadItems')))
      }

      if (localStorage.hasOwnProperty('isModalMinimised')) {
        commit('initialiseModal', JSON.parse(localStorage.getItem('isModalMinimised')))
      }
    },

    minimiseDownloadModal ({ commit }, boolean) {
      boolean ? commit('minimiseDownloadModal') : commit('maximiseDownloadModal')
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
      state.downloadItems = state.downloadItems.filter(download => download.id != item.id)
    },

    hideDownloadModal (state) {
      state.isModalActive = false
    },

    initialiseDownloadItems (state, downloadItems) {
      state.downloadItems = downloadItems
    },

    initialiseModal (state, isModalMinimised) {
      state.isModalMinimised = isModalMinimised
    },

    maximiseDownloadModal (state) {
      state.isModalMinimised = false
    },

    minimiseDownloadModal (state) {
      state.isModalMinimised = true
    },

    showDownloadModal (state) {
      state.isModalActive = true
    },

    updateLocalStorage (state) {
      localStorage.setItem('downloadItems', JSON.stringify(state.downloadItems))
    }
  }
}