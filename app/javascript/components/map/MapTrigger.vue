<template>
  <button
    class="map__trigger"
    @click="toggleMapPane"
    v-html="text"
  />
</template>
<script>
export default {
  name: 'MapTrigger',

  props: {
    text: {
      type: String,
      default: ''
    }
  },

  methods: {
    toggleMapPane () {
      this.$emit('toggle-map-pane')
    }
  }
}
</script>
