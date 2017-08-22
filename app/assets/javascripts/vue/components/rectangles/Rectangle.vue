<template>
  <div class="js-rectangle v-rectangles__rectangle" :style="styleObject">
    <div class="v-rectangles__content">
      <span class="js-value v-rectangles__title">{{ title }} ({{ styledKm }})</span>
    </div>
  </div>
</template>

<script>
  module.exports = {
    name: 'rectangle',

    props: {
      title: String,
      km: Number,
      percent: String,
      color: String
    },

    data: function() {
      return {
        styleObject: {
          backgroundColor: '',
          width: 0,
          height: 0
        }
      }
    },

    created: function() {
      this.styleObject.width = this.percent
      this.styleObject.height = this.percent
      this.styleObject.backgroundColor = this.color
    },

    mounted: function() {
      window.setTimeout(function(){
        $('.js-rectangle').addClass('v-rectangles__rectangle-animate')
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
