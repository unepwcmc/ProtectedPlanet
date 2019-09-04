import Vue from 'vue/dist/vue.esm'
import Vue2TouchEvents from 'vue2-touch-events'
import ScrollMagic from 'scrollmagic'

// components
import Carousel from './components/carousel/Carousel'
import CarouselSlide from './components/carousel/CarouselSlide'
import Counter from './components/counter/Counter'
import ChartBar from './components/charts/chart-bar/ChartBar'
import ChartBarSimple from './components/charts/chart-bar/ChartBarSimple'
import ChartBarStacked from './components/charts/chart-bar/ChartBarStacked'
import ChartLine from './components/charts/chart-line/ChartLine'
import ChartTreemapInteractive from './components/charts/chart-treemap/ChartTreemapInteractive'
import ChartRectangles from './components/charts/chart-rectangles/ChartRectangles'
import ChartSunburst from './components/charts/chart-sunburst/ChartSunburst'
import SelectWithContent from './components/select/SelectWithContent'
import StickyNav from './components/sticky/StickyNav'
import StickyTab from './components/sticky/StickyTab'
import SocialShareText from './components/social/SocialShareText'

document.addEventListener('DOMContentLoaded', () => { 
  if(document.getElementById('v-app')) {

    const app = new Vue({
      el: '#v-app',

      components: {
        Carousel,
        CarouselSlide,
        Counter,
        ChartBar,
        ChartBarSimple,
        ChartBarStacked,
        ChartLine,
        ChartTreemapInteractive,
        ChartRectangles,
        ChartSunburst,
        SelectWithContent,
        StickyNav,
        StickyTab,
        SocialShareText
      }
    })
  }
})


  