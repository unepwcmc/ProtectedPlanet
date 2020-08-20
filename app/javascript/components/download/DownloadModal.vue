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
      <p v-html="textDownload.citationText" />

      <ul class="modal__ul">
        <download-item 
          v-for="download in activeDownloads"
          class="modal__li"
          :endpointCreate="endpointCreate"
          :endpointPoll="endpointPoll"
          :key="download.id"
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

  computed: {
    activeDownloads () {
      return this.$store.state.download.downloadItems
    },

    isActive: {
      get () {
        return this.$store.state.download.isModalActive
      },
      set (boolean) {
        this.$store.dispatch('download/toggleDownloadModal', boolean)
      }
    },

    isMinimised: {
      get () {
        return this.$store.state.download.isModalMinimised
      },
      set (boolean) {
        this.$store.dispatch('download/minimiseDownloadModal', boolean)
      }
    }
  },

  watch: {
    activeDownloads () {
      if(this.activeDownloads.length == 0) { 
        this.$emit('deleted:all')
        this.isActive = false
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