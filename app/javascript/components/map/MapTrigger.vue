<template>
  <button
    class="map__trigger"
    @click="toggleMapPane"
  />
</template>
<script>
export default {
  name: 'map-trigger',

  methods: {
    toggleMapPane () {
      this.$emit('toggle-map-pane')
    }
  }
}
</script>