<template>
  <div class="map--filters">
    <div class="header">
      <div class="header--title">{{ title }}</div>
      <div class="header--close-button"></div>
    </div>
    <div class="search">
      <map-search />
    </div>
    <div class="overlays">
      <div class="overlays--overlay" v-for="(overlay, index) in overlays" :key="index">
        <v-map-filter :overlay="overlay" />
      </div>
    </div>

    <div class="disclaimer" v-if="disclaimer">
      <div class="disclaimer--heading">{{ disclaimer.heading }}}</div>
      <div class="disclaimer--body" v-html="disclaimer.body"></div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'VMapFilters',

  data () {
    return {
    }
  },

  props: {
    title: {
      type: String,
      required: true
    },
    disclaimer: {
      type: Object,
      required: false,
      validator: type => {
        return type.hasOwnProperty('heading') && type.heading instanceof String
          && type.hasOwnProperty('body') && type.heading instanceof String
      }
    }
  }

}
</script>