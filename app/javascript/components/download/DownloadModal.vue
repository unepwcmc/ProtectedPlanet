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
          :id="download.id"
          :has-failed="download.hasFailed"
          :key="download._uid"
          :text="textStatus"
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
    isActive: {
      default: false,
      type: Boolean
    },
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
      activeDownloads: [
        {
          id: '1',
          title: 'Filename 1',
          url: 'http://google.com',
          hasFailed: false
        },
        {
          id: '2',
          title: 'Filename 2',
          url: '',
          hasFailed: true
        },
        {
          id: '3',
          title: 'Filename 3',
          url: '',
          hasFailed: false
        },
      ],
    }
  },

  mounted () {
    
  },

  watch: {
    newDownload () {
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