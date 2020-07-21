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
      :newDownload="newDownload"
      :isActive="showDownloadModal"
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
    options: Array, //[ { title: String, commercialAvailable: Boolean, params: Object } ]
    text: String
  },

  data () {
    return {
      newDownload: {},
      // [
        // {
        //   id: 1,
        //   title: 'Filename 1',
        //   url: 'http://google.com',
        //   hasFailed: false
        // },
        // {
        //   id: 2,
        //   title: 'Filename 2',
        //   url: '',
        //   hasFailed: true
        // },
        // {
        //   id: 3,
        //   title: 'Filename 3',
        //   url: '',
        //   hasFailed: false
        // },
      // ],
      selectedDownloadOption: {},
      showCommercialModal: false,
      showDownloadModal: false,
      showPopup: false
    }
  },

  methods: {
    // addDownload (download) {
    //   console.log(download)
    //   this.downloads.push(download)
    //   console.log(this.downloads)
    // },

    ajaxRequest () {
      console.log('download data - HOOK BACK END UP')

      const endpoint = '/downloads'

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