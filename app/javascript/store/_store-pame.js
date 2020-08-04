export const storePame = {
  namespaced: true,

  state: {
    totalItemsOnCurrentPage: 0,
    requestedPage: 1,
    selectedFilterOptions: [], // an array containing an object for each filter that has an array of selected options
    modalContent: {},
    sortDirection: ''
  },

  mutations: {
    updateRequestedPage (state, page) {
      state.requestedPage = page
    },

    updateTotalItemsOnCurrentPage (state, total) {
      state.totalItemsOnCurrentPage = total
    },

    setFilterOptions (state, options) {
      state.selectedFilterOptions = options
    },

    updateFilterOptions (state, newOptions) {
      // find the correct filter to update
      state.selectedFilterOptions.forEach(filter => {
        if(filter.name == newOptions.filter){

          // replace filter options array with newOptions array
          filter.options = newOptions.options
        }
      })
    },

    clearFilterOptions (state) {
      state.selectedFilterOptions.forEach(filter => {
        filter.options = []
      })
    },

    removeFilterOption (state, removeOption) {
      state.selectedFilterOptions.forEach(filter => {
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
      state.modalContent = content
    },

    updateSortDirection (state, direction) {
      state.sortDirection = direction
    }
  }
}