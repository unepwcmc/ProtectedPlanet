<template>
  <li>
    <span class="modal__li-title">{{ title }}</span>

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
        this.hasFailed = response.data.hasFailed
        this.id = response.data.id
        this.title = response.data.title
        this.url = response.data.url
      })
      .catch(error => {
        console.log(error)
        this.hasFailed = true
        // this.id = toString(Math.random)
        this.title = `${this.params.token} .${this.params.format}`
        this.url = ''
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
          this.hasFailed = response.data.hasFailed
          this.title = response.data.title
          this.url = response.data.url
        })
        .catch(error => {
          console.log('error', error)
        })
    },

    deleteItem () {
      this.$store.dispatch('download/deleteDownloadItem', this.params)
    }, 

    startPolling () {
      this.interval = window.setInterval(this.ajaxRequestDownloadStatus, 10000)
    },

    stopPolling () {
      window.clearInterval(this.interval)
    }
  }
}
</script>