<template>
  <div
    v-if="show"
    class="v-map-filters"
    :class="{'v-map-filters--hidden': isHidden}"
  >
    <v-map-header
      v-model="title"
      closeable
      @close="onClose"
    />
    <div class="v-map-filters__body">
      <slot name="top" />
      <slot />
      <div class="v-map-filters__overlays">
        <div
          v-for="(overlay, index) in overlays"
          :key="index"
          class="v-map-filters__overlay"
        >
          <v-map-filter v-bind="overlay" />
        </div>
      </div>
      <slot name="bottom" />
    </div>
  </div>
</template>
<script>
import VMapFilter from './VMapFilter'
import VMapHeader from './VMapHeader'

import { disableTabbing } from '../../helpers/focus-helpers'

export default {
  name: 'VMapFilters',

  components: {
    VMapFilter,
    VMapHeader,
  },

  props: {
    overlays: {
      type: Array,
      required: true
    },
    title: {
      type: String,
      required: true
    },
    isHidden: {
      type: Boolean,
      default: false
    }
  },

  data () {
    return {
      show: true
    }
  },

  mounted () {
    if (this.isHidden) {
      disableTabbing(this.$el)
    }
  },

  methods: {
    onClose () {
      this.show = false
      this.$emit('show', false)
    }
  }
}
</script>
