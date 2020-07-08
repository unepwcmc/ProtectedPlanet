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

  data () {
    return {
      selectedBaselayerInternal: null
    }
  },

  computed: {
    selectedBaselayer () {
      return this.$store.state.map.selectedBaselayer
    }
  },

  watch: {
    selectedBaselayer () {
      this.selectedBaselayerInternal = this.selectedBaselayer
    },

    selectedBaselayerInternal () {
      this.updateBaselayerInStore()
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
      this.selectedBaselayerInternal = layer
    },

    updateBaselayerInStore () {
      this.$store.dispatch('map/updateSelelectedBaselayer', this.selectedBaselayerInternal)
    }
  }
}
</script>