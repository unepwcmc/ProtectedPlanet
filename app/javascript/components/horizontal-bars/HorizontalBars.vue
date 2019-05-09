<template>
  <div class="v-horizontal-bars">
    <horizontal-bar v-for="bar, key in bars" 
      :key="key"
      :name="bar.name"
      :km="bar.km"
      :url="bar.url"
      :percent="percent(bar.km)"
    >
    </horizontal-bar>
  </div>
</template>

<script>
  import ScrollMagic from 'scrollmagic'
  import HorizontalBar from './HorizontalBar'

  export default {
    name: 'horizontal-bars',

    components: { HorizontalBar },

    props: {
      json: { required: true }
    },

    data () {
      return {
        max: 0,
        bars: {}
      }
    },

    created () {
      this.bars = this.json
      this.calculateMax()
    },

    mounted () {
      this.scrollMagicHandlers()
    },

    methods: {
      scrollMagicHandlers () {
        const marineScrollMagic = new ScrollMagic.Controller()
        
        new ScrollMagic.Scene({ triggerElement: '.sm-size-distribution', reverse: false })
          .setClassToggle('.sm-size-distribution .sm-bar', 'v-horizontal-bars__bar-wrapper-animate')
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
        return Math.round((km / this.max)*100) + '%'
      }
    }
  }
</script>
