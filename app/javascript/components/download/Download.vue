<template>
  <div>
    <button
      class="download__trigger"
      @click="toggleDownloadPane"
    >
      <span class="download__trigger-text">{{ buttonText }}</span>
    </button>

    <div :class="['download__target', { 'active': showPopup }]">
      <download-popup
        :options="options"
        v-on:click:download:option="clickDownloadOption"
      />
    </div>

    <download-commercial 
      :isActive="showCommercialModal"
      :text="text.commercial"
      v-on:click:close-modal="closeCommercialModal"
      v-on:click:non-commercial="clickNonCommercial"
      />

    <download-modal 
      :isActive="showDownloadModal"
      :newDownload="newDownload"
      :text="text.download"
      :textStatus="text.status"
      v-on:deleted:all="closeDownloadModal"
    />
  </div>
</template>
<script>
import axios from 'axios'
import mixinAxiosHelpers from '../../mixins/mixin-axios-helpers'
import DownloadCommercial from './DownloadCommercial.vue'
import DownloadModal from './DownloadModal.vue'
import DownloadPopup from './DownloadPopup.vue'

export default {
  name: 'download',

  components: { DownloadCommercial, DownloadModal, DownloadPopup },

  mixins: [ mixinAxiosHelpers ],

  props: {
    buttonText: String,
    options: Array, //[ { title: String, commercialAvailable: Boolean, params: Object } ]
    text: {
      required: true,
      type: Object //See download_text in downloads_helper.rb
    }
  },

  data () {
    return {
      downloadRequestFailed: {
        id: '0',
        url: '',
        hasFailed: true
      },
      newDownload: {},
      selectedDownloadOption: {},
      showCommercialModal: false,
      showDownloadModal: false,
      showPopup: false
    }
  },

  methods: {
    addDownload (download) {
      console.log(download)
      this.downloads.push(download)
      console.log(this.downloads)
    },

    ajaxRequest () {
      console.log('download data - HOOK BACK END UP')

      const endpoint = '/downloads'
      const poll = '/downloads/poll' // get - send same params in an array

      let data = this.selectedDownloadOption.params
      console.log('data', data)

      this.axiosSetHeaders()

      axios.post(endpoint, data)
      .then(response => {
        console.log('success', response)
        this.newDownload = response.data
      })
      .catch(function (error) {
        console.log(error)
        this.downloadRequestFailed.title = `${data.token} .${data.domain}`
        this.newDownload = this.downloadRequestFailed
      })

      this.selectedDownloadOption = {}
    },

    clickDownloadOption (option) {
      this.showPopup = false
      this.selectedDownloadOption = option

      if(option.commercialAvailable) {
        this.showCommercialModal = true
      } else {
        this.showDownloadModal = true
        this.ajaxRequest()
      }
    },

    clickNonCommercial () {
      console.log('click non commercial')
      this.closeCommercialModal()
      this.showDownloadModal = true
      this.ajaxRequest()
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