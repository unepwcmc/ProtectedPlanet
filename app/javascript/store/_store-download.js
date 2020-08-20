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
      commit('maximiseDownloadModal')
      commit('showDownloadModal')
    },

    deleteDownloadItem ({ commit }, item) {
      commit('deleteDownloaditem', item)
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
    },

    toggleDownloadModal ({ commit }, boolean) {
      boolean ? commit('showDownloadModal') : commit('hideDownloadModal')
    },

    updateLocalStorage ({ commit }) {
      commit('updateLocalStorageDownloadItems')
      commit('updateLocalStorageBoolean', 'isModalActive')
      commit('updateLocalStorageBoolean', 'isModalMinimised')
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

    updateLocalStorageBoolean (state, property) {
      localStorage.setItem(property, state[property].toString())
    }
  }
}