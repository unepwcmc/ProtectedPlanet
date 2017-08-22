<template>
  <div>
    <p>{{ name }}</p>
    <div class="v-horizontal-bars__bar-wrapper">
      <span class="js-bar v-horizontal-bars__bar" :style="styleObject"></span>
      <span class="js-value v-horizontal-bars__value">{{ styledKm }} </span>
    </div>
  </div>
</template>

<script>
  module.exports = {
    name: 'horizontal-bar',

    props: {
      name: "",
      km: Number,
      percent: String
    },

    data: function() {
      return {
        styleObject: {
          width: 0
        }
      }
    },

    created: function() {
      this.styleObject.width = this.percent
    },

    mounted: function() {
      window.setTimeout(function(){
        $('.js-bar').addClass('v-horizontal-bars__bar-animate')
      }, 1000)

      window.setTimeout(function(){
        $('.js-value').addClass('v-horizontal-bars__value-animate')
      }, 1800)
    },

    computed: {
      styledKm: function () {
        return this.km.toLocaleString() + ' km²'
      }
    }
  }
</script>
