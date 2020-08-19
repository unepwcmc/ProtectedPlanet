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
    // hasFailed: {
    //   required: true,
    //   type: Boolean
    // },
    params: {
      required: true,
      type: Object //{ domain: String, token: String }
    },
    text: {
      required: true,
      type: Object //{ download: String, failed: String, generating: String }
    },
    // title: String,
    // url: {
    //   type: String
    // }
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
    // this.poll.hasFailed = this.hasFailed
    // this.poll.url = this.url

    this.axiosSetHeaders()
    this.ajaxRequestDownload()
    // this.startPolling()
  },

  methods: {
    ajaxRequestDownload () {
      console.log(this.params)
      axios.post(this.endpointCreate, this.params)
      .then(response => {
        console.log('success', response)
        // this.newDownload = response.data
        // this.$store.dispatch('download/addNewDownloadItem', response.data)

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

        // this.$store.dispatch('download/addNewDownloadItem', response.data)
        // this.newDownload = this.downloadRequestFailed
      })

      this.startPolling()
    },

    ajaxRequestDownloadStatus () {
      console.log('isready', this.isReady)
      console.log('failed', this.hasFailed)

      if(this.isReady || this.hasFailed) { 
        this.stopPolling() 
        return false
      }

      axios.get(this.endpointPoll, this.params)
        .then(response => {
          console.log('response', response)
          this.hasFailed = response.data.hasFailed
          this.title = response.data.title
          this.url = response.data.url
        })
        .catch(error => {
          console.log('error', error)
        })
    },

    deleteItem () {
      this.$emit('click:delete', this.id)
    }, 

    startPolling () {
      console.log('here')
      this.interval = window.setInterval(this.ajaxRequestDownloadStatus, 10000)
    },

    stopPolling () {
      window.clearInterval(this.interval)
    }
  }
}
</script>