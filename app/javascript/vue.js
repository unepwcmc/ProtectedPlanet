import Vue from 'vue/dist/vue.esm'

// components
import Carousel from './components/carousel/Carousel'
import CarouselSlide from './components/carousel/CarouselSlide'
import Counter from './components/counter/Counter'
import HorizontalBarChart from './components/bar-chart/HorizontalBarChart'
import HorizontalBars from './components/horizontal-bars/HorizontalBars'
import InteractiveMultiline from './components/interactive-multiline/InteractiveMultiline'
import InteractiveTreemap from './components/interactive-treemap/InteractiveTreemap'
import Rectangles from './components/rectangles/Rectangles'
import SelectWithContent from './components/select/SelectWithContent'
import StickyNav from './components/sticky-nav/StickyNav'
import StickyTab from './components/sticky-nav/StickyTab'
import Sunburst from './components/sunburst/Sunburst'
import TwitterShare from './components/twitter-share/TwitterShare'

document.addEventListener('DOMContentLoaded', () => { 
  if(document.getElementById('v-app')) {

    const app = new Vue({
      el: '#v-app',

      components: {
        Carousel,
        CarouselSlide,
        Counter,
        HorizontalBarChart,
        HorizontalBars,
        InteractiveMultiline,
        InteractiveTreemap,
        Rectangles,
        SelectWithContent,
        StickyNav,
        StickyTab,
        Sunburst,
        TwitterShare
      }
    })
  }
})


  // marineScrollMagic = new ScrollMagic.Controller()


  // new ScrollMagic.Scene({ triggerElement: '.sm-infographic', reverse: false })
  //   .setClassToggle('.sm-infographic .infographic__bar--pa', 'infographic__bar--pa--animate')
  //   .addTo(marineScrollMagic)



