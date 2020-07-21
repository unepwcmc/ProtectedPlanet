<template>
  <div 
    :class="['modal--download', { 'active' : isActive }]"
  >
    <div class="modal__topbar">
      <span>Downloads</span>
      <span
        class="modal__minimise"
        @click="toggle"
      />
    </div>
    <div 
      :class="['modal__content', { 'minimised': isMinimised }]"
    >
      <span class="modal__title">Citation</span>
      <p>UNEP-WCMC (2019). Protected Area Profile for France from the World Database of Protected Areas, December 2019. Available at: www.protectedplanet.net</p>

      <ul class="modal__ul">
        <download-item 
          v-for="download in activeDownloads"
          class="modal__li"
          :id="download.id"
          :has-failed="download.hasFailed"
          :key="download._uid"
          :title="download.title"
          :url="download.url"
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
    newDownload: Object, //{ title: String, url: String, hasFailed: Boolean }
    isActive: {
      default: false,
      type: Boolean
    }
  },

  data () {
    return {
      isMinimised: false,
      activeDownloads: []
    }
  },

  mounted () {
    
  },

  watch: {
    newDownload () {
      console.log('new', this.activeDownloads)
      this.activeDownloads.push(this.newDownload)
    }
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