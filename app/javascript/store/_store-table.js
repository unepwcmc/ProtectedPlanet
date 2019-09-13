import { eventHub } from '../vue.js'

export const storeTable = {
  namespaced: true,

  state: {
    sortDirection: '',
    sortField: '', 
    requestedPage: 1,
    searchTerm: ''
  },

  actions: {
    updateSearchTerm ({ commit }, searchTerm) {
      commit('updateSearchTerm', searchTerm)
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
    updateSearchTerm (state, searchTerm) {
      state.searchTerm = searchTerm
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