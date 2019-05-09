<template>
  <span v-if="total > 0">{{ styledNumber }}</span>
</template>

<script>
  import ScrollMagic from 'scrollmagic'

  export default {
    name: 'counter',

    props: {
      config: {
        type: Object,
        default () {
          return {
            speed: 30,
            divisor: 50
          }
        }
      },
      total: {
        type: Number,
        default: 0
      },
      animate: { default: false }
    },

    data() {
      return {
        number: 0,
        step: 0,
        increase: true
      }
    },

    created() {
      this.total = this.total
      this.calculateStep()
    },

    mounted() {
      if(this.animate){ this.count() }

      this.scrollMagicHandlers()
    },

    watch: {
      total () {
        this.calculateStep()
        this.count()
      }
    },

    methods: {
      count () {
        this.checkDirection()

        var interval = window.setInterval(() => {

          if(this.increase && this.number + this.step < this.total){
              this.increment()

          } else if (!this.increase && this.number - this.step > this.total ){
              this.decrement()

          } else {
            this.number = this.total
            clearInterval(interval)
          }
        }, this.config.speed)
      },

      increment () {
        this.number = this.number + this.step
      },

      decrement () {
        this.number = this.number - this.step
      },

      calculateStep () {
        this.step = Math.abs(this.total - this.number) / this.config.divisor
      },

      checkDirection () {
        if(this.number < this.total){
          this.increase = true
        } else {
          this.increase = false
        }
      },

      scrollMagicHandlers () {
        const counterScrollMagic = new ScrollMagic.Controller()

        // coverage stats shown over the map
        new ScrollMagic.Scene({ triggerElement: '.sm-coverage', reverse: false })
          .on('start', function () {
            if($(this.$el).hasClass('sm-coverage-counter')) { this.count() }
          })
          .addTo(counterScrollMagic)

        // national waters and high seas infographic
        new ScrollMagic.Scene({ triggerElement: '.sm-infographic', reverse: false })
          .on('start', function () {
            if($(this.$el).hasClass('sm-infographic-counter')) { this.count() }
          })
          .addTo(counterScrollMagic)

        // pledges
        new ScrollMagic.Scene({ triggerElement: '.sm-pledges', reverse: false })
          .on('start', function () {
            if($(this.$el).hasClass('sm-pledges')) { this.count() }
          })
          .addTo(counterScrollMagic)
      }
    },

    computed: {
      styledNumber () {
        var roundingNumber = 1

        if(this.total < 20) { roundingNumber = 10 }
        if(this.total < 17) { roundingNumber = 100 }

        return (Math.ceil(this.number * roundingNumber)/roundingNumber).toLocaleString()
      }
    }
  }
</script>
