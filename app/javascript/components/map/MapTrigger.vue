<template>
  <button
    :class="['map__trigger', buttonStateClass]"
    @click="toggleMapPane"
    v-html="text"
  />
</template>
<script>
export default {
  name: 'MapTrigger',

  model: {
    event: 'toggle:map-pane',
    prop: 'isActive'
  },

  props: {
    isDisabled: {
      type: Boolean,
      default: false
    },
    isActive: {
      type: Boolean,
      default: false
    },
    text: {
      type: String,
      default: ''
    }
  },

  computed: {
    buttonStateClass () {
      return {
        'disabled': this.isDisabled,
        'active': this.isActive
      }
    }
  },

  methods: {
    toggleMapPane () {
      if(this.isDisabled) { return false }
      
      this.$emit('toggle:map-pane', this.isActive)
    }
  }
}
</script>
