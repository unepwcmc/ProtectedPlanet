<template>
  <div class="v-map-baselayer-controls">
    <button
      v-for="layer in baselayers"
      :key="`baselayer-toggle-${layer.id}`"
      class="v-map-baselayer-controls__control"
      :class="{'selected': isSelected(layer)}"
      @click="selectBaselayer(layer)"
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
        this.$store.dispatch('map/updateSelelectedBaselayer', layer)
      }
    }
  },

  created () {
    this.selectBaselayer(this.baselayers[0])
  },

  methods: {
    isSelected (layer) {
      return layer.id === this.selectedBaselayer.id
    },

    selectBaselayer (layer) {
      this.selectedBaselayer = layer
    }
  }
}
</script>