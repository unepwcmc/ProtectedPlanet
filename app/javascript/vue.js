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
import AmChartLine from './components/charts/am-chart-line/AmChartLine'
import AmChartMultiline from './components/charts/am-chart-line/AmChartMultiline'
import AmChartPie from './components/charts/am-chart-pie/AmChartPie'
import Carousel from './components/carousel/Carousel'
import CarouselSlide from './components/carousel/CarouselSlide'
import Counter from './components/counter/Counter'
import ChartBar from './components/charts/chart-bar/ChartBar'
import ChartBarSimple from './components/charts/chart-bar/ChartBarSimple'
import ChartBarStacked from './components/charts/chart-bar/ChartBarStacked'
import ChartColumnTabbed from './components/charts/chart-column-tabbed/ChartColumnTabbed'
import ChartDial from './components/charts/chart-dial/ChartDial'
import ChartTreemapInteractive from './components/charts/chart-treemap/ChartTreemapInteractive'
import ChartRectangles from './components/charts/chart-rectangles/ChartRectangles'
import ChartRowPa from './components/charts/chart-row-pa/ChartRowPa'
import ChartRowStacked from './components/charts/chart-row-stacked/ChartRowStacked'
import ChartRowTarget from './components/charts/chart-row-target/ChartRowTarget'
import ChartSunburst from './components/charts/chart-sunburst/ChartSunburst'
import Download from './components/download/Download'
import DownloadModal from './components/download/DownloadModal'
import Flickity from 'vue-flickity'
import FilteredTable from './components/pame/FilteredTable'
import GaLink from './components/link/GaLink'
import ListingPage from './components/listing/ListingPage.vue'
import ListingPageCardNews from './components/listing/ListingPageCardNews.vue'
import ListingPageCardResources from './components/listing/ListingPageCardResources.vue'
import NavBurger from './components/nav/NavBurger'
import PameModal from './components/pame/PameModal'
import RegionCountryPages from './components/pages/RegionCountryPages'
import SearchAreas from './components/search/SearchAreas'
import SearchAreasHome from './components/search/SearchAreasHome'
import SearchSite from './components/search/SearchSite'
import SearchSiteTopbar from './components/search/SearchSiteTopbar'
import SelectEquity from './components/select/SelectEquity'
import SelectWithContent from './components/select/SelectWithContent'
import StickyBar from './components/sticky/StickyBar'
import StickyNav from './components/sticky/StickyNav'
import TableHead from './components/table/TableHead'
import Tabs from './components/tabs/Tabs'
import TabTarget from './components/tabs/TabTarget'
import Target11Dashboard from './components/pages/Target11Dashboard'
import Tooltip from './components/tooltip/Tooltip'
import TooltipSecond from './components/tooltip/TooltipSecond'
import VMapDisclaimer from './components/map/VMapDisclaimer'
import VMap from './components/map/VMap'
import VMapPASearch from './components/map/VMapPASearch'
import VMapHeader from './components/map/VMapHeader'
import VMapFilters from './components/map/VMapFilters'
import VSelectSearchable from './components/select/VSelectSearchable'
import VTable from './components/table/VTable'
import IconExclamationCircle from './components/icon/ExclamationCircle'
import StatsAttributesSet from './components/stats/StatsAttributesSet'
import StatsParcelsSources from './components/stats/StatsParcelsSources'
import BannerBanner from './components/banner/Banner'

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

    Vue.directive('click-outside', {
      bind: function (el, binding, vnode) {
        el.clickOutsideEvent = function (event) {
          if (!(el == event.target || el.contains(event.target))) {
            vnode.context[binding.expression](event);
          }
        };
        document.body.addEventListener('click', el.clickOutsideEvent)
      },
      unbind: function (el) {
        document.body.removeEventListener('click', el.clickOutsideEvent)
      },
    });

    const app = new Vue({
      el: '#v-app',
      store,
      components: {
        AmChartLine,
        AmChartMultiline,
        AmChartPie,
        Carousel,
        CarouselSlide,
        Counter,
        ChartBar,
        ChartBarSimple,
        ChartBarStacked,
        ChartDial,
        ChartColumnTabbed,
        ChartTreemapInteractive,
        ChartRectangles,
        ChartRowPa,
        ChartRowStacked,
        ChartRowTarget,
        ChartSunburst,
        Download,
        GaLink,
        DownloadModal,
	      FilteredTable,
        Flickity,
        ListingPage,
        ListingPageCardNews,
        ListingPageCardResources,
        NavBurger,
        PameModal,
        RegionCountryPages,
        SearchAreas,
        SearchAreasHome,
        SearchSite,
        SearchSiteTopbar,
        SelectEquity,
        SelectWithContent,
        StickyBar,
        StickyNav,
        TableHead,
        Tabs,
        TabTarget,
        Target11Dashboard,
        Tooltip,
        TooltipSecond,
        VMap,
        'v-map-pa-search': VMapPASearch,
        VMapDisclaimer,
        VMapHeader,
        VMapFilters,
        VSelectSearchable,
        VTable,
        IconExclamationCircle,
        StatsAttributesSet,
        StatsParcelsSources,
        BannerBanner
      },
      beforeCreate() { 
        this.$store.dispatch('download/initialiseStore')
      },
      mounted () {
        window.addEventListener('beforeunload', e => {
          this.$store.dispatch('download/updateLocalStorage')

          // the absence of a returnValue property on the event will guarantee the browser unload happens
          delete e['returnValue']
        })
      }
    })
  }
})