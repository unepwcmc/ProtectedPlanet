export const storeTable = {
  namespaced: true,

  state: {
    sortDirection: '',
    sortField: '', 
    requestedPage: 1
  },

  actions: {
    updateSortParameters ({ commit, state }, sortParamters) {
      commit('updateSortDirection', sortParamters.direction)
      commit('updateSortField', sortParamters.field)
      commit('updateRequestedPage', 1)
    },
  },

  mutations: {
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