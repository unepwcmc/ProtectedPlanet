<template>
  <button
    class="filter__trigger"
    @click="toggleFilterPane"
    v-html="text"
  />
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