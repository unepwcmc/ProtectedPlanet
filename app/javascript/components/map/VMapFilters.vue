<template>
  <div
    v-if="show"
    class="v-map-filters"
  >
    <div class="header">
      <v-map-header 
        closeable
        v-model="title"
        @close="onClose"
      />
    </div>
    <div class="body">
      <div class="search">
        <v-map-pa-search />
      </div>
      <div class="overlays">
        <div
          v-for="(overlay, index) in overlays"
          :key="index"
          class="overlays--overlay"
        >
          <v-map-filter v-bind="overlay" />
        </div>
      </div>

      <div
        v-if="disclaimer"
        class="disclaimer"
      >
        <div class="disclaimer--heading">
          {{ disclaimer.heading }}
        </div>
        <div
          class="disclaimer--body"
          v-html="disclaimer.body"
        />
      </div>
    </div>
  </div>
</template>
<script>
import VMapFilter from './VMapFilter'
import VMapHeader from './VMapHeader'
import VMapPASearch from './VMapPASearch'

export default {
  name: 'VMapFilters',

  components: {
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
    disclaimer: {
      type: Object,
      required: false,
      validator: type => {
        return type.hasOwnProperty('heading') && typeof type.heading === 'string'
          && type.hasOwnProperty('body') && typeof type.heading === 'string'
      },
      default: () => ({})
    }
  },

  data () {
    return {
      show: true
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
