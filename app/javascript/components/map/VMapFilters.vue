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
      <div class="overlays--layer" v-for="(layer, index) in overlays" :key="index">
        <v-map-filter-layer :layer="layer" />
      </div>
    </div>

    <div class="disclaimer" v-if="disclaimer">
      <slot name="disclaimer">
        <div class="disclaimer--heading">{{ disclaimer.heading }}}</div>
        <div class="disclaimer--body" v-html="disclaimer.body"></div>
      </slot>
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