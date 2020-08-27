<template>
  <li>
    <span class="modal__li-title">{{ titleTrimmed }}</span>

    <span 
      class="modal__li-failed"
      v-show="hasFailed"
    >{{ text.failed }}</span>

    <span 
      class="modal__li-generating"
      v-show="isGenerating"
    >{{ text.generating }}</span>

    <a 
      class="modal__li-download"
      :href="url"  
      v-show="isReady"
    >{{ text.download }}</a>

    <span 
      class="modal__li-delete" 
      @click="deleteItem"
    />
  </li>
</template>
<script>
import axios from 'axios'
import mixinAxiosHelpers from '../../mixins/mixin-axios-helpers'

export default {
  name: 'download-item',

  mixins: [ mixinAxiosHelpers ],

  props: {
    endpointCreate: {
      required: true,
      type: String
    },
    endpointPoll: {
      required: true,
      type: String
    },
    params: {
      required: true,
      type: Object //{ domain: String, token: String }
    },
    text: {
      required: true,
      type: Object //{ download: String, failed: String, generating: String }
    },
  },

  data () {
    return {
      fakeItem: false,
      fakeItemData: {
        hasFailed: true,
        url: ''
      },
      hasFailed: false,
      id: '',
      interval: null,
      title: '',
      url: ''
    }
  },

  computed: {
    isGenerating () {
      return !this.hasFailed && this.url == ''
    },
    
    isReady () {
      return this.url != ''
    },

    titleTrimmed () {
      return this.title.length <= 30 ? this.title : this.title.substring(0,27) + '...'
    }
  },

  mounted () {
    this.axiosSetHeaders()
    this.ajaxRequestDownload()
  },

  watch: {

  },

  methods: {
    ajaxRequestDownload () {
      axios.post(this.endpointCreate, this.params)
      .then(response => {
        this.updateDownloadItem(response.data)
      })
      .catch(error => {
        console.log(error)
        this.fakeItem = true
        this.fakeItemData.title = `${this.params.token} .${this.params.format}`
        this.updateDownloadItem(this.fakeItemData)
      })

      this.startPolling()
    },

    ajaxRequestDownloadStatus () {
      if(this.isReady || this.hasFailed) { 
        this.stopPolling() 
        return false
      }

      axios.get(this.endpointPoll, {
          params: this.params
        })
        .then(response => {
          this.updateDownloadItem(response.data)
        })
        .catch(error => {
          console.log('error', error)
          this.stopPolling()
          this.hasFailed = true
        })
    },

    deleteItem () {
      this.$store.dispatch('download/deleteDownloadItem', this.params)
    }, 

    startPolling () {
      this.interval = window.setInterval(this.ajaxRequestDownloadStatus, 15000)
    },

    stopPolling () {
      window.clearInterval(this.interval)
    },

    updateDownloadItem (data) {
      this.hasFailed = data.hasFailed
      this.id = 'id' in data ? data.id : Math.round(Math.random(0,1)*100000)
      this.title = data.title
      this.url = data.url
    }
  }
}
</script>