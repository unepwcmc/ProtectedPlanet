<template>
  <div class="v-rectangles">
    <rectangle v-for="rectangle, key in rectangles"
      :key="key"
      :title="rectangle.title"
      :km="rectangle.km"
      :percent="percent(rectangle.km)"
      :color="color(key)"
    >
    </rectangle>
  </div>
</template>

<script>
  import ScrollMagic from 'scrollmagic'
  import Rectangle from './Rectangle'

  export default {
    name: 'rectangles',

    components: { Rectangle },

    props: {
      json: { required: true }
    },

    data() {
      return {
        max: 0,
        rectangles: [],
        colors: [
          '#90BDC4',
          '#729099'
        ]
      }
    },

    created() {
      this.rectangles = this.json
      this.calculateMax()
    },

    mounted () {
      this.scrollMagicHandlers()
    },

    methods: {
      scrollMagicHandlers () {
        const marineScrollMagic = new ScrollMagic.Controller()
        
        new ScrollMagic.Scene({ triggerElement: '.sm-size-distribution', reverse: false })
          .setClassToggle('.sm-size-distribution .sm-rectangle', 'v-rectangles__rectangle-animate')
          .addTo(marineScrollMagic)
      },

      calculateMax () {
        let array = []

        this.json.forEach((dataset) => {
          array.push(dataset.km)
        })

        this.max = Math.max.apply(null, array)
      },

      percent (km) {
        return `${Math.round((km / this.max)*100)}%`
      },

      color (key) {
        return this.colors[key]
      }
    },
  }
</script>