<template>
  <button
    class="filter__trigger"
    @click="toggleFilterPane"
  />
</template>
<script>
export default {
  name: 'filter-trigger',

  methods: {
    toggleFilterPane () {
      this.$emit('toggle-filter-pane')
    }
  }
}
</script>