import Vue from 'vue/dist/vue.esm'

// components
import Carousel from './components/carousel/Carousel'
import CarouselSlide from './components/carousel/CarouselSlide'
import StickyNav from './components/sticky-nav/StickyNav'
import StickyTab from './components/sticky-nav/StickyTab'

document.addEventListener('DOMContentLoaded', () => { 
  if(document.getElementById('v-app')) {

    const app = new Vue({
      el: '#v-app',

      components: {
        Carousel,
        CarouselSlide,
        StickyNav,
        StickyTab
      }
    })
  }
})