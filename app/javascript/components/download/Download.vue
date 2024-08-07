<template>
  <div>
    <button
      :class="['download__trigger', { 'disabled': downloadDisabled }]"
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
      :text="textCommercial"
      v-on:click:close-modal="closeCommercialModal"
      v-on:click:non-commercial="clickNonCommercial"
      />
  </div>
</template>
<script>
import mixinAxiosHelpers from '../../mixins/mixin-axios-helpers'
import DownloadCommercial from './DownloadCommercial.vue'
import DownloadPopup from './DownloadPopup.vue'

export default {
  name: 'download',

  components: { DownloadCommercial, DownloadPopup },

  mixins: [ mixinAxiosHelpers ],

  props: {
    buttonText: String,
    options: Array, //[ { title: String, commercialAvailable: Boolean, params: Object } ]
    textCommercial: {
      required: true,
      type: Object //See download_text in downloads_helper.rb
    },
    downloadDisabled: {
      default: false,
      required: false,
      type: Boolean
    },
    gaId: {
      type: String,
      required: true
    }
  },

  data () {
    return {
      selectedDownloadOption: {},
      showCommercialModal: false,
      showPopup: false
    }
  },

  methods: {
    addNewDownloadItem () {
      let item = this.selectedDownloadOption.params

      item.id = Math.round(Math.random(0,1)*100000)
      
      this.$store.dispatch('download/addNewDownloadItem', item)
      this.selectedDownloadOption = {}
    },

    clickDownloadOption (option) {
      this.showPopup = false
      this.selectedDownloadOption = option

      if(option.commercialAvailable) {
        this.showCommercialModal = true
      } else {
        this.addNewDownloadItem()
      }

      if(this.gaId) {
        const eventLabel = `${this.gaId} request - ${option.title}`

        this.$ga.event('Button', 'click', eventLabel)
      }
    },

    clickNonCommercial () {
      if(this.selectedDownloadOption.params.domain == 'search') {
        this.selectedDownloadOption.params.filters = this.$store.state.download.searchFilters
        this.selectedDownloadOption.params.search = this.$store.state.download.searchTerm
      }

      this.closeCommercialModal()
      this.addNewDownloadItem()
    },

    closeCommercialModal () {
      this.showCommercialModal = false
    },

    toggleDownloadPane () {
      if (this.downloadDisabled) return;
      this.showPopup = !this.showPopup
    }
  }
}
</script>