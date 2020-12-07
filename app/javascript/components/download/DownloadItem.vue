<template>
  <li>
    <span class="modal__li-title">{{ titleTrimmed }}</span>

    <p 
      class="modal__li-failed"
      v-show="hasFailed"
    >
      <span class="modal__li-text">{{ text.failed }}</span>
    </p>

    <p 
      class="modal__li-generating"
      v-show="isGenerating"
    >
      <span class="modal__li-text">{{ text.generating }}</span>
    </p>

    <a 
      class="modal__li-download"
      :href="url"  
      v-show="isReady"
      @click="downloadItem"
    >
      <span class="modal__li-text">{{ text.download }}</span>
    </a>

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
      url: '',
      updatedParams: ''
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
          params: this.updatedParams
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
      this.stopPolling()
    }, 

    downloadItem () {
      if(this.gaId) {
        const eventLabel = `${this.gaId} file - ${this.title}`
        this.$ga.event('Button', 'click', eventLabel)
      }
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
      this.updatedParams = {...this.params, backEndToken: data.token}
    }
  }
}
</script>