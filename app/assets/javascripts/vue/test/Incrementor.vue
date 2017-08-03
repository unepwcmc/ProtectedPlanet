<template>
  <span class="v-incrementor">
    {{ styledNumber }} 
  </span>
</template>

<script>
  module.exports = {
    name: 'incrementor',

    props: {
      type: String,
      total: { 
        required: true,
        type: Number
      }
    },

    data() {
      return {
        config: {
          speedMs: 30,
          divisor: 50
        },
        number: 0,
        incrementValue: 0
      }
    },

    created() {
      this.calculateIncrementValue()
    },

    mounted() {
      this.animate()
    },

    methods: {
      animate: function(){
        var self = this

        var interval = window.setInterval(function(){
          if(self.number + self.incrementValue < self.total){
            self.increment()
          } else {
            self.number = self.total
            clearInterval(interval)
          }
        }, this.config.speedMs)
      },

      increment: function(){
        this.number = this.number + this.incrementValue
      },

      calculateIncrementValue: function(){
        this.incrementValue = this.total / this.config.divisor
      }
    },

    computed: {
      styledNumber: function(){
        return (Math.ceil(this.number * 10)/10).toLocaleString()
      }
    }
  }
</script>