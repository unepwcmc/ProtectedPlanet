<template>
  <div>
    <p class="v-horizontal-bars__title">
      <a :href="url" :title="'View the ' + name + ' protected area'" target="_blank">{{ name }}</a>
    </p>
    <div class="v-horizontal-bars__bar-wrapper sm-bar">
      <span class="v-horizontal-bars__bar" :style="styleObject"></span>
      <span class="v-horizontal-bars__value">{{ styledKm }} </span>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'horizontal-bar',

    props: {
      name: "",
      km: Number,
      percent: String,
      url: String
    },

    data () {
      return {
        styleObject: {
          width: 0
        }
      }
    },

    created () {
      this.styleObject.width = this.percent
    },

    computed: {
      styledKm () {
        return this.km.toLocaleString() + ' km²'
      }
    }
  }
</script>
