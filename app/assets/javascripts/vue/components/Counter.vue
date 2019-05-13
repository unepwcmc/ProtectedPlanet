<template>
  <span>{{ styledNumber }}</span>
</template>

<script>
  module.exports = {
    name: 'counter',

    props: {
      config: {
        type: Object,
        default: function () {
          return {
            speed: 30,
            divisor: 50
          }
        }
      },
      total: {
        required: true,
        type: Number
      },
      animate: { default: false }
    },

    data: function() {
      return {
        number: 0,
        step: 0,
        increase: true
      }
    },

    created: function() {
      this.total = this.total
      this.calculateStep()
    },

    mounted: function() {
      if(this.animate){ this.count() }

      this.scrollMagicHandlers()
    },

    watch: {
      total: function () {
        this.calculateStep()
        this.count()
      }
    },

    methods: {
      count: function () {
        var self = this

        this.checkDirection()

        var interval = window.setInterval(function () {

          if(self.increase && self.number + self.step < self.total){
              self.increment()

          } else if (!self.increase && self.number - self.step > self.total ){
              self.decrement()

          } else {
            self.number = self.total
            clearInterval(interval)
          }
        }, this.config.speed)
      },

      increment: function () {
        this.number = this.number + this.step
      },

      decrement: function () {
        this.number = this.number - this.step
      },

      calculateStep: function () {
        this.step = Math.abs(this.total - this.number) / this.config.divisor
      },

      checkDirection: function () {
        if(this.number < this.total){
          this.increase = true
        } else {
          this.increase = false
        }
      },

      scrollMagicHandlers: function () {
        counterScrollMagic = new ScrollMagic.Controller()
        var self = this

        // coverage stats shown over the map
        new ScrollMagic.Scene({ triggerElement: '.sm-coverage', reverse: false })
          .on('start', function () {
            if($(self.$el).hasClass('sm-coverage-counter')) { self.count() }
          })
          .addTo(counterScrollMagic)

        // national waters and high seas infographic
        new ScrollMagic.Scene({ triggerElement: '.sm-infographic', reverse: false })
          .on('start', function () {
            if($(self.$el).hasClass('sm-infographic-counter')) { self.count() }
          })
          .addTo(counterScrollMagic)

        // pledges
        new ScrollMagic.Scene({ triggerElement: '.sm-pledges', reverse: false })
          .on('start', function () {
            if($(self.$el).hasClass('sm-pledges')) { self.count() }
          })
          .addTo(counterScrollMagic)
      }
    },

    computed: {
      styledNumber: function () {
        var roundingNumber = 1

        if(this.total < 20) { roundingNumber = 10 }
        if(this.total < 17) { roundingNumber = 100 }
        if(this.config.decimal) { roundingNumber = Math.pow(10, this.config.decimal) }

        console.log(roundingNumber)

        return (Math.ceil(this.number * roundingNumber)/roundingNumber).toLocaleString()
      }
    }
  }
</script>
