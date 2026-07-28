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

// store
import store from './store/store.js'

// components
import AmChartMultiline from './components/charts/am-chart-line/AmChartMultiline'
import AmChartPie from './components/charts/am-chart-pie/AmChartPie'
import ChartBarStacked from './components/charts/chart-bar/ChartBarStacked'
import ChartRowPa from './components/charts/chart-row-pa/ChartRowPa'
import ChartRowStacked from './components/charts/chart-row-stacked/ChartRowStacked'
import Flickity from 'vue-flickity'
import FilteredTable from './components/pame/FilteredTable'
import PameModal from './components/pame/PameModal'
import RegionCountryPages from './components/pages/RegionCountryPages'
import SearchSite from './components/search/SearchSite'
import StickyBar from './components/sticky/StickyBar'
import Tabs from './components/tabs/Tabs'
import TabTarget from './components/tabs/TabTarget'
import Tooltip from './components/tooltip/Tooltip'
import TooltipSecond from './components/tooltip/TooltipSecond'
import VSelectSearchable from './components/select/VSelectSearchable'
import IconExclamationCircle from './components/icon/ExclamationCircle'
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
      store,
      components: {
        AmChartMultiline,
        AmChartPie,
        ChartBarStacked,
        ChartRowPa,
        ChartRowStacked,
        FilteredTable,
        Flickity,
        PameModal,
        RegionCountryPages,
        SearchSite,
        StickyBar,
        Tabs,
        TabTarget,
        Tooltip,
        TooltipSecond,
        VSelectSearchable,
        IconExclamationCircle
      }
    })
  }
})