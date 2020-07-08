<template>
  <div
    class="v-map-filter" 
    :class="{ 'v-map-filter--toggleable': isToggleable }"
    @click.stop="onClick"
  >
    <div
      class="color"
      :style="{ backgroundColor: color }"
    />
    <div class="description">
      {{ title }}
    </div>
    <div
      v-if="isToggleable"
      class="active-toggler"
    >
      <v-map-toggler v-model="isShown" />
    </div>
  </div>
</template>
<script>
import VMapToggler from './VMapToggler'

export default {
  name: 'VMapFilter',

  components: {
    VMapToggler,
  },

  props: {
    color: {
      type: String,
      default: '#cccccc'
    },
    title: {
      type: String,
      required: true
    },
    isShownByDefault: {
      type: Boolean,
      default: true
    },
    isToggleable: {
      type: Boolean,
      default: true
    },
    layers: {
      type: Array,
      required: true
    },
    id: {
      type: String,
      required: true
    }
  },

  computed: {
    overlayForStore () {
      return {layers: this.layers, id: this.id}
    },

    visibleOverlays () {
      return this.$store.state.map.visibleOverlays
    },

    isShown: {
      get () {
        return Boolean(this.visibleOverlays.filter(o => o.id === this.id).length)
      },

      set (isShown) {
        isShown ? this.addToStore() : this.removeFromStore()
      }
    }
  },

  created () {
    this.isShown = this.isShownByDefault
  },

  methods: {
    onClick () {
      if (this.isToggleable) {
        this.isShown = !this.isShown
      }
    },

    addToStore () {
      this.$store.dispatch('map/addOverlay', this.overlayForStore)
    },

    removeFromStore () {
      this.$store.dispatch('map/removeOverlay', this.overlayForStore)
    }
  },
}
</script>