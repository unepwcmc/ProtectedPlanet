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
  module.exports = {
    name: 'horizontal-bar',

    props: {
      name: "",
      km: Number,
      percent: String,
      url: String
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

    computed: {
      styledKm: function () {
        return this.km.toLocaleString() + ' km²'
      }
    }
  }
</script>
