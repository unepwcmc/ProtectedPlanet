<template>
  <div
    v-if="show"
    class="v-map-filters"
  >
    <v-map-header 
      closeable
      v-model="title"
      @close="onClose"
    />
    <div class="v-map-filters__body">
      <v-map-pa-search />
      <div class="v-map-filters__overlays">
        <div
          v-for="(overlay, index) in overlays"
          :key="index"
          class="v-map-filters__overlay"
        >
          <v-map-filter v-bind="overlay" />
        </div>
      </div>

      <div
        v-if="disclaimer"
        class="v-map-disclaimer"
      >
        <div class="v-map-disclaimer__heading">
          {{ disclaimer.heading }}
        </div>
        <div
          class="v-map-disclaimer__body"
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
