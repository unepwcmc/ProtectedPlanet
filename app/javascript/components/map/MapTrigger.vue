<template>
  <button
    class="map__trigger"
    @click="toggleMapPane"
    v-html="text"
  />
</template>
<script>
export default {
  name: 'map-trigger',

  props: {
    text: String
  },

  methods: {
    toggleMapPane () {
      this.$emit('toggle-map-pane')
    }
  }
}
</script>
