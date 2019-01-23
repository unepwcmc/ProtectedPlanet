$(document).ready( -> 
  new Vue({
    el: '.home-parent',
    components: {
      'carousel': VComponents['vue/components/Carousel']
    }
  })
)
