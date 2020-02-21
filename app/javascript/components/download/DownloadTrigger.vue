<template>
  <button
    class="download__trigger"
    @click="toggleDownloadPane"
    v-html="text"
  />
</template>
<script>
export default {
  name: 'download-trigger',

  props: {
    text: String
  },

  methods: {
    toggleDownloadPane () {
      this.$emit('toggle-download-pane')
    }
  }
}
</script>