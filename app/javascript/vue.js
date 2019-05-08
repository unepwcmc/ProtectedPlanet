import Vue from 'vue/dist/vue.esm'

// components
import Carousel from './components/carousel/Carousel'
import CarouselSlide from './components/carousel/CarouselSlide'
import HorizontalBars from './components/horizontal-bars/HorizontalBars'
import StickyNav from './components/sticky-nav/StickyNav'
import StickyTab from './components/sticky-nav/StickyTab'

document.addEventListener('DOMContentLoaded', () => { 
  if(document.getElementById('v-app')) {

    const app = new Vue({
      el: '#v-app',

      components: {
        Carousel,
        CarouselSlide,
        HorizontalBars,
        StickyNav,
        StickyTab
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



  // new ScrollMagic.Scene({ triggerElement: '.sm-size-distribution', reverse: false })
  // .setClassToggle('.sm-size-distribution .sm-rectangle', 'v-rectangles__rectangle-animate')
  // .addTo(marineScrollMagic)