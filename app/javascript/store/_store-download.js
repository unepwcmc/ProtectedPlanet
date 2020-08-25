export const storeDownload = {
  namespaced: true,

  state: {
    downloadItems: [],
    isModalActive: false,
    isModalMinimised: false,
    searchFilters: [],
    searchTerm: ''
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
        try {
          commit('initialiseDownloadItems', JSON.parse(localStorage.getItem('downloadItems')))
        } catch (e) {
            console.error(e)
            console.log(window.localStorage.getItem('downloadItems'))
            commit('resetDownloadItems')
        }
      }
      
      if (localStorage.hasOwnProperty('isModalActive')) {
        try {
          commit('initialiseModalActive', !!JSON.parse(localStorage.getItem('isModalActive')))
        } catch (e) {
          console.error(e)
          console.log(window.localStorage.getItem('isModalActive'))
          commit('hideDownloadModal')
        }
      }

      if (localStorage.hasOwnProperty('isModalMinimised')) {
        try {
          commit('initialiseModalMinimised', !!JSON.parse(localStorage.getItem('isModalMinimised')))
        } catch (e) {
          console.error(e)
          console.log(window.localStorage.getItem('isModalMinimised'))
          commit('minimiseDownloadModal')
        }
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
    },

    updateSearchFilters ({ commit }, filters) {
      commit('updateSearchFilters', filters)
    },

    updateSearchTerm ({ commit }, searchTerm) {
      commit('updateSearchTerm', searchTerm)
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

    resetDownloadItems (state) {
      state.downloadItems = []
    },

    showDownloadModal (state) {
      state.isModalActive = true
    },

    updateLocalStorageDownloadItems (state) {
      localStorage.setItem('downloadItems', JSON.stringify(state.downloadItems))
    },

    updateLocalStorageBoolean (state, property) {
      localStorage.setItem(property, state[property].toString())
    },

    updateSearchFilters (state, filters) {
      state.searchFilters = filters
    },

    updateSearchTerm (state, searchTerm) {
      state.searchTerm = searchTerm
    }
  }
}