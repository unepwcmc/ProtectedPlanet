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
      <v-map-pa-search
        v-if="searchTypes.length"
        v-bind="{ searchTypes, dropdownLabel }"
        @change="onSearch"
      />
      <div class="v-map-filters__overlays">
        <div
          v-for="(overlay, index) in overlays"
          :key="index"
          class="v-map-filters__overlay"
        >
          <v-map-filter v-bind="overlay" />
        </div>
      </div>

      <v-map-disclaimer
        v-if="disclaimer"
        class="v-map-disclaimer--embedded"
        :disclaimer="disclaimer"
      />
    </div>
  </div>
</template>
<script>
import VMapDisclaimer from './VMapDisclaimer'
import VMapFilter from './VMapFilter'
import VMapHeader from './VMapHeader'
import VMapPASearch from './VMapPASearch'

import { disableTabbing } from '../../helpers/focus-helpers'

export default {
  name: 'VMapFilters',

  components: {
    VMapDisclaimer,
    VMapFilter,
    VMapHeader,
    'v-map-pa-search': VMapPASearch,
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
    dropdownLabel: {
      type: String,
      default: ''
    },
    searchTypes: {
      type: Array,
      default: () => []
    },
    disclaimer: {
      type: Object,
      default: null
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
    },

    onSearch (search) {
      // LOGIC GOES HERE FOR INITIATING MAP CHANGE
      console.log({ search })
    }
  }
}
</script>
