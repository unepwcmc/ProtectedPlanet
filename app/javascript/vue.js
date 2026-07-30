import 'babel-polyfill'
import { findPolyfill } from './utilities/polyfill-find'
import 'url-search-params-polyfill'
findPolyfill()

// dependencies
import Vue from 'vue/dist/vue.esm'
import VueAnalytics from 'vue-analytics'
import Vue2TouchEvents from 'vue2-touch-events'
import VueLazyload from 'vue-lazyload'

// cookieconsent
import 'cookieconsent'
import 'cookieconsent/build/cookieconsent.min.css'

// components
import StickyBar from './components/sticky/StickyBar'
import Tabs from './components/tabs/Tabs'
import TabTarget from './components/tabs/TabTarget'
// BannerBanner migrated to a Vite/Vue 3 island (app/frontend/components/Banner.vue,
// mounted via layout.ts). Kept out of the Vue 2 #v-app root so only one system compiles it.

document.addEventListener('DOMContentLoaded', () => {
  if(document.getElementById('v-app')) {
    
    if(process.env.NODE_ENV == 'development' || process.env.NODE_ENV == 'staging') {
      Vue.use(VueAnalytics, { id: 'UA-12920389-5' }) // staging
    } else if(process.env.NODE_ENV == 'production') {
      Vue.use(VueAnalytics, { id: 'UA-12920389-2' }) // production
    }

    Vue.prototype.$eventHub = new Vue()

    Vue.use(Vue2TouchEvents)

    Vue.use(VueLazyload)

    new Vue({
      el: '#v-app',
      components: {
        StickyBar,
        Tabs,
        TabTarget
      }
    })
  }
})