<template>
  <div class="v-map-baselayer-controls">
    <button
      v-for="layer in baselayers"
      :key="`baselayer-toggle-${layer.id}`"
      class="v-map-baselayer-controls__control"
      @click="updateBaselayer(layer)"
    >
      {{ layer.id }}
    </button>
  </div>
</template>

<script>
export default {
  name: 'VMapBaselayerControls',

  props: {
    baselayers: {
      type: Array,
      default: () => []
    }
  },

  methods: {
    updateBaselayer (layer) {
      this.$emit('update:baselayer', layer)
    }
  }
}
</script>