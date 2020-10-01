<template>
  <span v-if="total >= 0">{{ styledNumber }}</span>
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
      decimal: {
        type: Number,
        default: 2
      },
      total: {
        type: Number,
        required: true,
      },
      trigger: { 
        type: String,
        required: true
      },
      animate: { default: false } //animate on page load
    },

    data() {
      return {
        number: 0,
        step: 0,
        increase: true
      }
    },

    created() {
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

        new ScrollMagic.Scene({ triggerElement: `.${this.trigger}`, reverse: false })
          .on('start', () => { this.count() })
          .addTo(counterScrollMagic)
      }
    },

    computed: {
      styledNumber () {
        const roundingNumber = Math.pow(10, this.decimal)

        return (Math.round(this.number * roundingNumber)/roundingNumber).toLocaleString()
      }
    }
  }
</script>
