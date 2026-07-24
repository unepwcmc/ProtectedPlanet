<template>
  <div>
    <button
      :class="['download__trigger', { 'button--disabled': downloadDisabled }]"
      :disabled="downloadDisabled"
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

      // The global download modal moved to a Vue3/Pinia island (Wave 4); this
      // component hasn't migrated yet (its :download-disabled prop is bound to
      // SearchAreas.vue's own reactive state — Wave 7), so it feeds the shared
      // store via a window bridge instead of Vuex — see
      // app/frontend/stores/downloadBridge.ts.
      window.__downloadStoreBridge?.addNewDownloadItem(item)
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
        // SearchAreas.vue writes these into the Vue3/Pinia download store now
        // (Wave 4) rather than Vuex — see app/frontend/stores/downloadBridge.ts.
        this.selectedDownloadOption.params.filters = window.__downloadStoreBridge?.getSearchFilters()
        this.selectedDownloadOption.params.search = window.__downloadStoreBridge?.getSearchTerm()
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