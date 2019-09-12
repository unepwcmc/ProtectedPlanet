// dependencies
import Vue from 'vue/dist/vue.esm'
import Vue2TouchEvents from 'vue2-touch-events'
import ScrollMagic from 'scrollmagic'

// store
import store from './store/store.js'

// components
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
import SelectWithContent from './components/select/SelectWithContent'
import StickyBar from './components/sticky/StickyBar'
import StickyNav from './components/sticky/StickyNav'
import StickyTab from './components/sticky/StickyTab'
import SocialShareText from './components/social/SocialShareText'
import Tooltip from './components/tooltip/Tooltip'
import VSelectSearchable from './components/select/VSelectSearchable'
import VTable from './components/table/VTable'

// eventhub
export const eventHub = new Vue()

document.addEventListener('DOMContentLoaded', () => { 
  if(document.getElementById('v-app')) {

    Vue.use(Vue2TouchEvents)
    
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
        ChartLine,
        ChartTreemapInteractive,
        ChartRectangles,
        ChartRowTarget,
        ChartSunburst,
        SelectWithContent,
        StickyBar,
        StickyNav,
        StickyTab,
        SocialShareText,
        Tooltip,
        VSelectSearchable,
        VTable
      }
    })
  }
})