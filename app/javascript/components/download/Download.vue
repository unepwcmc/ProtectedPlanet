<template>
  <div>
    <button
      class="download__trigger"
      @click="toggleDownloadPane"
    >
      <span class="download__trigger-text">{{ text }}</span>
    </button>

    <div :class="['download__target', { 'active': showPopup }]">
      <download-popup
        :options="options"
        v-on:click:download:option="clickDownloadOption"
      />
    </div>

    <download-commercial 
      :isActive="showCommercialModal"
      v-on:click:non-commercial="clickNonCommercial"
      />

    <download-modal 
      :isActive="showDownloadModal"
    />
  </div>
</template>
<script>
import DownloadCommercial from './DownloadCommercial.vue'
import DownloadModal from './DownloadModal.vue'
import DownloadPopup from './DownloadPopup.vue'

export default {
  name: 'download',

  components: { DownloadCommercial, DownloadModal, DownloadPopup },

  props: {
    options: Array, //[ { title: String, commercialAvailable: Boolean, params: Object } ]
    text: String
  },

  data () {
    return {
      showCommercialModal: false,
      showDownloadModal: false,
      showPopup: false
    }
  },

  methods: {
    clickDownloadOption (option) {
      this.showPopup = false

      if(option.commercialAvailable) {
        this.showCommercialModal = true
      } else {
        this.showDownloadModal = true
      }
    },

    clickNonCommercial () {
      this.showCommercialModal = false
      this.showDownloadModal = true
      alert('download data - HOOK BACK END UP')
    },

    toggleDownloadPane () {
      this.showPopup = !this.showPopup
    },
  }
}
</script>