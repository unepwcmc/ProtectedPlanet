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
        <v-map-filter v-bind="overlay" />
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
    overlays: {
      type: Array,
      required: true
    },
    title: {
      type: String,
      required: true
    },
    disclaimer: {
      type: Object,
      required: false,
      validator: type => {
        return type.hasOwnProperty('heading') && typeof type.heading === 'string'
          && type.hasOwnProperty('body') && typeof type.heading === 'string'
      }
    }
  }

}
</script>