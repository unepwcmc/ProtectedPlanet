<template>
  <div 
    :class="['modal--download', { 'active' : isActive }]"
  >
    <div class="modal__topbar">
      <span>{{ textDownload.title }}</span>
      <span
        class="modal__minimise"
        @click="toggle"
      />
    </div>
    <div 
      :class="['modal__content', { 'minimised': isMinimised }]"
    >
      <span class="modal__title">{{ textDownload.citationTitle }}</span>
      <p>{{ textDownload.citationText }}</p>

      <ul class="modal__ul">
        <download-item 
          v-for="(download, index) in activeDownloads"
          class="modal__li"
          :endpointCreate="endpointCreate"
          :endpointPoll="endpointPoll"
          :key="index"
          :params="download"
          :text="textStatus"
        />
      </ul>
    </div>
  </div>
</template>
<script>
import DownloadItem from './DownloadItem.vue'

export default {
  name: 'download-modal',

  components: { DownloadItem },

  props: {
    endpointCreate: {
      required: true,
      type: String
    },
    endpointPoll: {
      required: true,
      type: String
    },
    textDownload: {
      required: true,
      type: Object //{ citationText: String, citationTitle: String, title: String }
    },
    textStatus: {
      required: true,
      type: Object
    }
  },

  data () {
    return {
      isMinimised: false,
      activeDownloads: this.$store.state.download.downloadItems,
    }
  },

  computed: {
    isActive: {
      get () {
        return this.$store.state.download.isModalActive
      },
      set (boolean) {
        this.$store.dispatch('download/toggleDownloadModal', boolean)
      }
    }
  },

  mounted () {
    console.log(this.activeDownloads.length)
    if(this.activeDownloads.length > 0) { 
      this.isActive = true
    }
  },

  watch: {
    activeDownloads () {
      console.log('active downloads changed')
      if(this.activeDownloads.length == 0) { 
        this.$emit('deleted:all')
        this.isMinimised = false
      }
    }
  },

  methods: {
    toggle () {
      this.isMinimised = !this.isMinimised
    }
  }
}
</script>