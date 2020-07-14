import { polyfill } from 'es6-object-assign'
import { findPolyfill } from './utilities/polyfill-find'
findPolyfill()
polyfill()

// dependencies
import Vue from 'vue/dist/vue.esm'
import VueAnalytics from 'vue-analytics'
import Vue2TouchEvents from 'vue2-touch-events'
import VueLazyload from 'vue-lazyload'

// store
import store from './store/store.js'

// components
import Carousel from './components/carousel/Carousel'
import CarouselSlide from './components/carousel/CarouselSlide'
import Counter from './components/counter/Counter'
import ChartBar from './components/charts/chart-bar/ChartBar'
import ChartBarSimple from './components/charts/chart-bar/ChartBarSimple'
import ChartBarStacked from './components/charts/chart-bar/ChartBarStacked'
import ChartColumnTabbed from './components/charts/chart-column-tabbed/ChartColumnTabbed'
import ChartDial from './components/charts/chart-dial/ChartDial'
import ChartLine from './components/charts/chart-line/ChartLine'
import ChartTreemapInteractive from './components/charts/chart-treemap/ChartTreemapInteractive'
import ChartRectangles from './components/charts/chart-rectangles/ChartRectangles'
import ChartRowPa from './components/charts/chart-row-pa/ChartRowPa'
import ChartRowTarget from './components/charts/chart-row-target/ChartRowTarget'
import ChartSunburst from './components/charts/chart-sunburst/ChartSunburst'
import Flickity from 'vue-flickity';
import Download from './components/download/Download'
import NavBurger from './components/nav/NavBurger'
import SearchAreas from './components/search/SearchAreas'
import SearchAreasHome from './components/search/SearchAreasHome'
import SearchSite from './components/search/SearchSite'
import SearchSiteTopbar from './components/search/SearchSiteTopbar'
import SelectWithContent from './components/select/SelectWithContent'
import StickyBar from './components/sticky/StickyBar'
import StickyNav from './components/sticky/StickyNav'
import TableHead from './components/table/TableHead'
import Tabs from './components/tabs/Tabs'
import TabTarget from './components/tabs/TabTarget'
import Target11Dashboard from './components/pages/Target11Dashboard'
import Tooltip from './components/tooltip/Tooltip'
import VMapDisclaimer from './components/map/VMapDisclaimer'
import VMap from './components/map/VMap'
import VMapHeader from './components/map/VMapHeader'
import VMapFilters from './components/map/VMapFilters'
import VSelectSearchable from './components/select/VSelectSearchable'
import VTable from './components/table/VTable'

document.addEventListener('DOMContentLoaded', () => {
  if(document.getElementById('v-app')) {

    Vue.use(VueAnalytics, { id: 'UA-12920389-2' }) // production

    Vue.prototype.$eventHub = new Vue()

    Vue.use(Vue2TouchEvents)

    Vue.use(VueLazyload)

    const app = new Vue({
      el: '#v-app',
      store,

      components: {
        Carousel,
        CarouselSlide,
        Counter,
        ChartBar,
        ChartBarSimple,
        ChartBarStacked,
        ChartDial,
        ChartColumnTabbed,
        ChartLine,
        ChartTreemapInteractive,
        ChartRectangles,
        ChartRowPa,
        ChartRowTarget,
        ChartSunburst,
        Download,
        Flickity,
        NavBurger,
        SearchAreas,
        SearchAreasHome,
        SearchSite,
        SearchSiteTopbar,
        SelectWithContent,
        StickyBar,
        StickyNav,
        TableHead,
        Tabs,
        TabTarget,
        Target11Dashboard,
        Tooltip,
        VMap,
        VMapDisclaimer,
        VMapHeader,
        VMapFilters,
        VSelectSearchable,
        VTable
      }
    })
  }
})
