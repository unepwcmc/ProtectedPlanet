<template>
  <button
    :class="['filter__trigger', { 'disabled': isDisabled }]"
    class="filter__trigger"
    @click="toggleFilterPane"
  >
    <span
      v-html="text"
      class="button__text"
    />
  </button>
</template>
<script>
export default {
  name: 'filter-trigger',

  props: {
    isDisabled: {
      default: false,
      type: Boolean
    },
    text: String
  },

  methods: {
    toggleFilterPane () {
      if(this.isDisabled) { return false }
      
      this.$emit('toggle:filter-pane')
    }
  }
}
</script>