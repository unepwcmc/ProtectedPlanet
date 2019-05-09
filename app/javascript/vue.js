import Vue from 'vue/dist/vue.esm'

// components
import Carousel from './components/carousel/Carousel'
import CarouselSlide from './components/carousel/CarouselSlide'
import HorizontalBars from './components/horizontal-bars/HorizontalBars'
import Rectangles from './components/rectangles/Rectangles'
import StickyNav from './components/sticky-nav/StickyNav'
import StickyTab from './components/sticky-nav/StickyTab'
import TwitterShare from './components/twitter-share/TwitterShare'

document.addEventListener('DOMContentLoaded', () => { 
  if(document.getElementById('v-app')) {

    const app = new Vue({
      el: '#v-app',

      components: {
        Carousel,
        CarouselSlide,
        HorizontalBars,
        Rectangles,
        StickyNav,
        StickyTab,
        TwitterShare
      }
    })
  }
})


  // marineScrollMagic = new ScrollMagic.Controller()


  // new ScrollMagic.Scene({ triggerElement: '.sm-infographic', reverse: false })
  //   .setClassToggle('.sm-infographic .infographic__bar--pa', 'infographic__bar--pa--animate')
  //   .addTo(marineScrollMagic)

  // new ScrollMagic.Scene({ triggerElement: '.sm-bar-chart', reverse: false })
  //   .setClassToggle('.sm-bar-chart', 'd3-horizontal-bar-chart-animate')
  //   .addTo(marineScrollMagic)



