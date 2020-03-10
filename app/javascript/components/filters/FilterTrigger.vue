<template>
  <button
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
    text: String
  },

  methods: {
    toggleFilterPane () {
      this.$emit('toggle-filter-pane')
    }
  }
}
</script>