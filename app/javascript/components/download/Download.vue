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
      v-on:click:close-modal="closeCommercialModal"
      v-on:click:non-commercial="clickNonCommercial"
      />

    <download-modal 
      :downloads="downloads"
      :isActive="showDownloadModal"
      v-on:deleted:all="closeDownloadModal"
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
      downloads: [
        {
          id: 1,
          title: 'Filename 1',
          url: 'http://google.com',
          hasFailed: false
        },
        {
          id: 2,
          title: 'Filename 2',
          url: '',
          hasFailed: true
        },
        {
          id: 3,
          title: 'Filename 3',
          url: '',
          hasFailed: false
        },
      ],
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
      this.closeModal()
      this.showDownloadModal = true
      alert('download data - HOOK BACK END UP')
    },

    closeCommercialModal () {
      this.showCommercialModal = false
    },

    closeDownloadModal () {
      console.log('close')
      this.showDownloadModal = false
    },

    toggleDownloadPane () {
      this.showPopup = !this.showPopup
    },
  }
}
</script>