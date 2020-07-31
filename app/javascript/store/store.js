// polyfills
import { polyfill } from 'es6-promise'
polyfill()

// dependencies
import Vue from 'vue/dist/vue.esm'
import Vuex from 'vuex/dist/vuex.esm'

Vue.use(Vuex)

// stores
import { storeTable } from './_store-table.js'
import { storeMap } from './_store-map.js'

export default new Vuex.Store({
  modules: {
    table: storeTable,
    map: storeMap
  }
})
