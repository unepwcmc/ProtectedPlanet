<template>
  <div 
    :class="['modal--download', { 'active' : isActive }]"
  >
    <div class="modal__topbar">
      <span>{{ text.title }}</span>
      <span
        class="modal__minimise"
        @click="toggle"
      />
    </div>
    <div 
      :class="['modal__content', { 'minimised': isMinimised }]"
    >
      <span class="modal__title">{{ text.citationTitle }}</span>
      <p>{{ text.citationText }}</p>

      <ul class="modal__ul">
        <download-item 
          v-for="download in activeDownloads"
          class="modal__li"
          :endpointCreate="endpointCreate"
          :endpointPoll="endpointPoll"
          id="2"
          :key="1"
          :params="download"
          :text="textStatus"
          v-on:click:delete="deleteItem"
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
    isActive: {
      default: false,
      type: Boolean
    },
    // paramsPoll: {
    //   required: true,
    //   type: Object //{ domain: String, token: String }
    // },
    newDownload: Object, //{ title: String, url: String, hasFailed: Boolean }
    text: {
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

  mounted () {
    console.log('any download', this.activeDownloads.length)
    if(this.activeDownloads.length > 0) { this.isActive = true }
  },

  watch: {
    // newDownload () {
    //   console.log('new', this.activeDownloads)
    //   this.activeDownloads.push(this.newDownload)
    // }
  },

  methods: {
    toggle () {
      this.isMinimised = !this.isMinimised
    },

    deleteItem (downloadId) {
      this.activeDownloads = this.activeDownloads.filter(download => download.id != downloadId )
      
      if(this.activeDownloads.length == 0) { 
        this.$emit('deleted:all')
        this.isMinimised = false
      }
    }
  }
}
</script>