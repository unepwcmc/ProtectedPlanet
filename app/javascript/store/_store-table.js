export const storeTable = {
  namespaced: true,

  state: {
    sortDirection: '',
    sortField: '', 
    requestedPage: 1,
    searchId: '',
    searchTerm: ''
  },

  actions: {
    updateSearchParameters ({ commit }, searchParameters) {
      commit('updateSearchId', searchParameters.id)
      commit('updateSearchType', searchParameters.obj_type)
      commit('updateSortDirection', '')
      commit('updateSortField', '')
      commit('updateRequestedPage', 1)
    },
    updateSortParameters ({ commit }, sortParamters) {
      commit('updateSortDirection', sortParamters.direction)
      commit('updateSortField', sortParamters.field)
      commit('updateRequestedPage', 1)
    },
    updatePage ({ commit }, requestedPage) {
      commit('updateRequestedPage', requestedPage)
    }
  },

  mutations: {
    updateSearchId (state, searchId) {
      state.searchId = searchId
    },
    updateSearchType (state, searchType) {
      state.searchType = searchType
    },
    updateRequestedPage (state, page) {
      state.requestedPage = page
    },
    updateSortDirection (state, direction) {
      state.sortDirection = direction
    },
    updateSortField (state, field) {
      state.sortField = field
    },
  }
}