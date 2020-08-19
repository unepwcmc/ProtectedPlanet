<template>
  <li>
    <span class="modal__li-title">{{ title }}</span>

    <span 
      class="modal__li-failed"
      v-show="poll.hasFailed"
    >{{ text.failed }}</span>

    <span 
      class="modal__li-generating"
      v-show="isGenerating"
    >{{ text.generating }}</span>

    <a 
      class="modal__li-download"
      :href="poll.url"  
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
    endpoint: {
      required: true,
      type: String
    },
    id: {
      required: true,
      type: String
    },
    hasFailed: {
      required: true,
      type: Boolean
    },
    paramsPoll: {
      required: true,
      type: Object //{ domain: String, token: String }
    },
    text: {
      required: true,
      type: Object //{ download: String, failed: String, generating: String }
    },
    title: String,
    url: {
      type: String
    }
  },

  data () {
    return {
      interval: null,
      poll: {
        hasFailed: false,
        url: ''
      }
    }
  },

  computed: {
    isGenerating () {
      return !this.poll.hasFailed && this.url == ''
    },
    
    isReady () {
      return this.poll.url != ''
    }
  },

  mounted () {
    this.poll.hasFailed = this.hasFailed
    this.poll.url = this.url

    this.axiosSetHeaders()
    this.startPolling()
  },

  methods: {
    ajaxRequestDownloadStatus () {
      console.log('isready', this.isReady)
      console.log('failed', this.poll.hasFailed)

      if(this.isReady || this.poll.hasFailed) { 
        this.stopPolling() 
        return false
      }

      axios.get(this.endpoint, this.paramsPoll)
        .then(response => {
          console.log('response', response)
          this.poll.hasFailed = response.data.hasFailed
          this.poll.url = response.data.url
        })
        .catch(error => {
          console.log('error', error)
        })
    },

    deleteItem () {
      this.$emit('click:delete', this.id)
    }, 

    startPolling () {
      this.interval = window.setInterval(this.ajaxRequestDownloadStatus, 1000)
    },

    stopPolling () {
      window.clearInterval(this.interval)
    }
  }
}
</script>