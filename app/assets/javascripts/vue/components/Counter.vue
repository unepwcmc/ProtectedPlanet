<template>
  <span>{{ styledNumber }}</span>
</template>

<script>
  module.exports = {
    name: 'counter',

    props: {
      config: {
        type: Object,
        default: function(){
          return {
            speed: 30,
            divisor: 50
          }
        }
      },
      total: { 
        required: true,
        type: Number
      }
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
      this.animate()
    },

    watch: {
      total: function(){
        this.calculateStep()
        this.animate()
      }
    },

    methods: {
      animate: function(){
        var self = this
        
        this.checkDirection()

        var interval = window.setInterval(function(){

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

      increment: function(){
        this.number = this.number + this.step
      },

      decrement: function(){
        this.number = this.number - this.step
      },

      calculateStep: function(){
        this.step = Math.abs(this.total - this.number) / this.config.divisor
      },

      checkDirection: function(){
        if(this.number < this.total){
          this.increase = true
        } else {
          this.increase = false
        }
      }
    },

    computed: {
      styledNumber: function(){
        return (Math.ceil(this.number * 10)/10).toLocaleString()
      }
    }
  }
</script>
