<template>
  <div class="sm-rectangle v-rectangles__rectangle" :style="styleObject">
    <div class="v-rectangles__content">
      <span class="v-rectangles__title">{{ title }} ({{ styledKm }})</span>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'chart-rectangle',

    props: {
      title: String,
      km: Number,
      percent: String,
      color: String
    },

    data () {
      return {
        styleObject: {
          backgroundColor: '',
          width: 0,
          height: 0
        }
      }
    },

    created () {
      this.styleObject.width = this.percent
      this.styleObject.height = this.percent
      this.styleObject.backgroundColor = this.color
    },

    computed: {
      styledKm () {
        return `${this.km.toLocaleString()} km²`
      }
    }
  }
</script>
