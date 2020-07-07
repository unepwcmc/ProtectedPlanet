<template>
  <div>
    <button
      class="download__trigger"
      @click="toggleDownloadPane"
    >
      <span class="download__trigger-text">{{ text }}</span>
    </button>

    <div :class="['download__target', { 'active': isActive }]">
      <download-popup
        :options="options"
        v-on:click:download:option="clickDownloadOption"
      />
    </div>
  </div>
</template>
<script>
import DownloadPopup from './DownloadPopup.vue'

export default {
  name: 'download',

  components: { DownloadPopup },

  props: {
    options: Array, //[ { title: String, commercialAvailable: Boolean, params: Object } ]
    text: String
  },

  data () {
    return {
      isActive: false
    }
  },

  methods: {
    clickDownloadOption (option) {
      if(option.commercialAvailable == true) {
        console.log('show commerical modal')
      } else {
        console.log('start download')
      }
    },

    toggleDownloadPane () {
      // this.$emit('toggle-download-pane')
      this.isActive = !this.isActive
    },
  }
}
</script>