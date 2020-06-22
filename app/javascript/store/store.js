// polyfills
import { polyfill } from 'es6-promise'
polyfill()

// dependencies
import Vue from 'vue/dist/vue.esm'
import Vuex from 'vuex/dist/vuex.esm'

Vue.use(Vuex)

// stores
import { storeTable } from './_store-table.js'

export default new Vuex.Store({
  modules: {
    table: storeTable
  },
    mutations: {
	setFilterOptions (state, options) {
	    this.state.selectedFilterOptions = options
	},
    }
})
