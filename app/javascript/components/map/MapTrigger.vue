<template>
  <button
    :class="['map__trigger', { 'disabled': isDisabled }]"
    @click="toggleMapPane"
    v-html="text"
  />
</template>
<script>
export default {
  name: 'MapTrigger',

  props: {
    isDisabled: {
      type: Boolean,
      default: false
    },
    text: {
      type: String,
      default: ''
    }
  },

  methods: {
    toggleMapPane () {
      if(this.isDisabled) { return false }
      
      this.$emit('toggle:map-pane')
    }
  }
}
</script>
