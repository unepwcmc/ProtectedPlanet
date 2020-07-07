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
      <v-map-toggler v-model="isActive" />
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
    }

  },

  data () {
    return {
      isActive: this.isShownByDefault
    }
  },

  watch: {
    isActive (isActive) {
      this.$emit('change', { isActive })
    }
  },

  methods: {
    onClick () {
      if (this.isToggleable) {
        this.isActive = !this.isActive
      }
    }
  },
}
</script>