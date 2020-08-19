import { polyfill } from 'es6-promise'
polyfill()

import Vue from 'vue/dist/vue.esm'
import Vuex from 'vuex/dist/vuex.esm'

Vue.use(Vuex)

import { storeMap } from './_store-map.js'
import { storePame } from './_store-pame.js'
import { storeTable } from './_store-table.js'

export default new Vuex.Store({
  modules: {
    map: storeMap,
    pame: storePame,
    table: storeTable
  }
})
