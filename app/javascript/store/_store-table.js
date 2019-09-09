export const storeTable = {
  namespaced: true,

  state: {
    sortDirection: '',
    sortField: '', 
    requestedPage: 1
  },

  actions: {
    updateSortParameters ({ commit }, sortParamters) {
      commit('updateSortDirection', sortParamters.direction)
      commit('updateSortField', sortParamters.field)
      commit('updateRequestedPage', 1)
    },
  },

  mutations: {
    updateRequestedPage (state, page) {
      this.state.requestedPage = page
    },
    updateSortDirection (state, direction) {
      this.state.sortDirection = direction
    },
    updateSortField (state, field) {
      this.state.sortField = field
    },
  }
}