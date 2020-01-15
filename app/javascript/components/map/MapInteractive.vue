<template>
  <div :class="classes">
    <v-map
      :mapbox-token="mapboxToken"
      class="map__mapbox"
    />
  </div>
</template>

<script>
import VMap from './VMap'

export default {
  name: 'map-interactive',

  components: { VMap },

  props: {
    classes: {
      type: String
    }
  },

  data () {
    return {
      mapboxToken: process.env.MAPBOX_TOKEN
    }
  }
}
</script>