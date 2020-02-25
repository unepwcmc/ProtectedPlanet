import { polyfill } from 'es6-object-assign'
import { findPolyfill } from './utilities/polyfill-find'
findPolyfill()
polyfill()

// dependencies
import Vue from 'vue/dist/vue.esm'
import VueAnalytics from 'vue-analytics'
import Vue2TouchEvents from 'vue2-touch-events'
import ScrollMagic from 'scrollmagic'
// import VueAgile from 'vue-agile'

// store
import store from './store/store.js'

// components
import Agile from './components/carousel/Agile'
import Carousel from './components/carousel/Carousel'
import CarouselSlide from './components/carousel/CarouselSlide'
import Counter from './components/counter/Counter'
import ChartBar from './components/charts/chart-bar/ChartBar'
import ChartBarSimple from './components/charts/chart-bar/ChartBarSimple'
import ChartBarStacked from './components/charts/chart-bar/ChartBarStacked'
import ChartDial from './components/charts/chart-dial/ChartDial'
import ChartLine from './components/charts/chart-line/ChartLine'
import ChartTreemapInteractive from './components/charts/chart-treemap/ChartTreemapInteractive'
import ChartRectangles from './components/charts/chart-rectangles/ChartRectangles'
import ChartRowTarget from './components/charts/chart-row-target/ChartRowTarget'
import ChartSunburst from './components/charts/chart-sunburst/ChartSunburst'
import MapInteractive from './components/map/MapInteractive'
import NavBurger from './components/nav/NavBurger'
import Search from './components/search/Search'
import SearchAutocompleteTypes from './components/search/SearchAutocompleteTypes'
import SearchResults from './components/search/SearchResults'
import SearchResultsAreas from './components/search/SearchResultsAreas'
import SearchSite from './components/search/SearchSite'
import SelectWithContent from './components/select/SelectWithContent'
import StickyBar from './components/sticky/StickyBar'
import StickyNav from './components/sticky/StickyNav'
import StickyTab from './components/sticky/StickyTab'
import SocialShareText from './components/social/SocialShareText'
import TableHead from './components/table/TableHead'
import Target11Dashboard from './components/pages/Target11Dashboard'
import Tooltip from './components/tooltip/Tooltip'
import VSelectSearchable from './components/select/VSelectSearchable'
import VTable from './components/table/VTable'

document.addEventListener('DOMContentLoaded', () => { 
  if(document.getElementById('v-app')) {

    Vue.use(VueAnalytics, { id: 'UA-12920389-2' }) // production

    Vue.prototype.$eventHub = new Vue()

    Vue.use(Vue2TouchEvents)
    
    const app = new Vue({
      el: '#v-app',
      store,

      components: {
        Agile,
        Carousel,
        CarouselSlide,
        Counter,
        ChartBar,
        ChartBarSimple,
        ChartBarStacked,
        ChartDial,
        ChartLine,
        ChartTreemapInteractive,
        ChartRectangles,
        ChartRowTarget,
        ChartSunburst,
        MapInteractive,
        NavBurger,
        Search,
        SearchAutocompleteTypes,
        SearchResults,
        SearchResultsAreas,
        SearchSite,
        SelectWithContent,
        StickyBar,
        StickyNav,
        StickyTab,
        SocialShareText,
        TableHead,
        Target11Dashboard,
        Tooltip,
        VSelectSearchable,
        VTable
      }
    })
  }
})