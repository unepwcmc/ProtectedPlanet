<template>
  <div>
    <button
      class="download__trigger"
      @click="toggleDownloadPane"
    >
      <span class="download__trigger-text">{{ text }}</span>
    </button>

    <div :class="['download__target', { 'active': isActive }]">
      <slot />
    </div>
  </div>
</template>
<script>
export default {
  name: 'download',

  props: {
    text: String
  },

  data () {
    return {
      isActive: false
    }
  },

  methods: {
    toggleDownloadPane () {
      // this.$emit('toggle-download-pane')
      this.isActive = !this.isActive
    }
  }
}
</script>