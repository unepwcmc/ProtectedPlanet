import { polyfill } from 'es6-promise'
polyfill()

import Vue from 'vue/dist/vue.esm'
import Vuex from 'vuex/dist/vuex.esm'

Vue.use(Vuex)

// create store
export default new Vuex.Store({
  state: {
    totalItemsOnCurrentPage: 0,
    requestedPage: 1,
    selectedFilterOptions: [], // an array containing an object for each filter that has an array of selected options
    modalContent: {},
    sortDirection: ''
  },

  mutations: {
    updateRequestedPage (state, page) {
      this.state.requestedPage = page
    },

    updateTotalItemsOnCurrentPage (state, total) {
      this.state.totalItemsOnCurrentPage = total
    },

    setFilterOptions (state, options) {
      this.state.selectedFilterOptions = options
    },

    updateFilterOptions (state, newOptions) {
      // find the correct filter to update
      this.state.selectedFilterOptions.forEach(filter => {
        if(filter.name == newOptions.filter){

          // replace filter options array with newOptions array
          filter.options = newOptions.options
        }
      })
    },

    clearFilterOptions () {
      this.state.selectedFilterOptions.forEach(filter => {
        filter.options = []
      })
    },

    removeFilterOption (state, removeOption) {
      this.state.selectedFilterOptions.forEach(filter => {
        if(filter.name == removeOption.name){ 
          filter.options.forEach(option => {
            if(option == removeOption.option){
              const index = filter.options.indexOf(removeOption.option)

              filter.options.splice(index, 1)
            }
          })
        }
      })
    },

    updateModalContent (state, content) {
      this.state.modalContent = content
    },

    updateSortDirection (state, direction) {
      this.state.sortDirection = direction
    }
  }
})
