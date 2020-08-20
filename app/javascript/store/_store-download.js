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
      commit('updateLocalStorageDownloadItems')
      commit('minimiseDownloadModal', false)
      commit('toggleDownloadModal', true)
    },

    deleteDownloadItem ({ commit }, item) {
      commit('deleteDownloaditem', item)
      commit('updateLocalStorageDownloadItems')
    },

    initialiseStore ({ commit }) {
      if (localStorage.hasOwnProperty('downloadItems')) {
        commit('initialiseDownloadItems', JSON.parse(localStorage.getItem('downloadItems')))
      }
      
      if (localStorage.hasOwnProperty('isModalActive')) {
        commit('initialiseModalActive', !!JSON.parse(localStorage.getItem('isModalActive')))
      }

      if (localStorage.hasOwnProperty('isModalMinimised')) {
        commit('initialiseModalMinimised', !!JSON.parse(localStorage.getItem('isModalMinimised')))
      }
    },

    minimiseDownloadModal ({ commit }, boolean) {
      boolean ? commit('minimiseDownloadModal') : commit('maximiseDownloadModal')
      commit('updateLocalStorageModalMinimised')
    },

    toggleDownloadModal ({ commit }, boolean) {
      boolean ? commit('showDownloadModal') : commit('hideDownloadModal')
      commit('updateLocalStorageModalActive')
    }
  },

  mutations: {
    addNewDownloadItem (state, item) {
      let downloadItems = _.cloneDeep(state.downloadItems)
      downloadItems.push(item)
      state.downloadItems = _.cloneDeep(downloadItems)
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

    initialiseModalActive (state, isModalActive) {
      state.isModalActive = isModalActive
    },

    initialiseModalMinimised (state, isModalMinimised) {
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

    updateLocalStorageDownloadItems (state) {
      localStorage.setItem('downloadItems', JSON.stringify(state.downloadItems))
    },

    updateLocalStorageModalActive (state) {
      localStorage.setItem('isModalActive', state.isModalActive.toString())
    },

    updateLocalStorageModalMinimised (state) {
      localStorage.setItem('isModalMinimised', state.isModalMinimised.toString())
    }
  }
}