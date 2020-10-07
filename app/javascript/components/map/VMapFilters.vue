<template>
  <div
    class="v-map-filters"
    :class="{'v-map-filters--hidden': isHidden}"
  >
    <v-map-header
      :title="title"
      :filters-shown="show"
      closeable
      @toggle="onToggle"
    />
    <div
      v-show="show"
      class="v-map-filters__body">
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
    onToggle () {
      this.show = !this.show
    }
  }
}
</script>
