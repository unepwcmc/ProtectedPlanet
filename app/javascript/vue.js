import 'babel-polyfill'
import { findPolyfill } from './utilities/polyfill-find'
import 'url-search-params-polyfill'
findPolyfill()

// dependencies
import Vue from 'vue/dist/vue.esm'
import Vue2TouchEvents from 'vue2-touch-events'
import VueLazyload from 'vue-lazyload'

// No components left to register here — every former #v-app widget is now a
// Vite/Vue 3 island (see app/frontend/entrypoints/layout.ts). #v-app itself,
// this file, and Webpacker are dead weight at this point; kept as a no-op
// bootstrap until they're removed outright (see [[tabs-wiring-blocked-on-vapp]]).

document.addEventListener('DOMContentLoaded', () => {
  if(document.getElementById('v-app')) {

    Vue.prototype.$eventHub = new Vue()

    Vue.use(Vue2TouchEvents)
    Vue.use(VueLazyload)
  }
})