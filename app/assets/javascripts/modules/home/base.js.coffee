$(document).ready( -> 
  new Vue({
    el: '.home-parent',
    components: {
      'carousel': VComponents['vue/components/carousel/Carousel']
      'carousel-slide': VComponents['vue/components/carousel/CarouselSlide']
    }
  })
)
