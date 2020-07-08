<template>
  <div class="v-map-baselayer-controls">
    <button
      v-for="layer in baselayers"
      :key="`baselayer-toggle-${layer.id}`"
      class="v-map-baselayer-controls__control"
      :class="{
        selected: layer.id === selectedBaselayer.id
      }"
      @click="selectedBaselayer = layer"
    >
      {{ layer.name }}
    </button>
  </div>
</template>

<script>
export default {
  name: 'VMapBaselayerControls',

  props: {
    baselayers: {
      type: Array,
      required: true
    }
  },

  computed: {
    selectedBaselayer: {
      get () {
        return this.$store.state.map.selectedBaselayer
      },

      set (layer) {
        this.$store.dispatch('map/updateSelectedBaselayer', layer)
      }
    }
  },

  created () {
    this.selectedBaselayer = this.baselayers[0]
  }
}
</script>