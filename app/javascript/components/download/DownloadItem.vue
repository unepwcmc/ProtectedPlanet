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
export default {
  name: 'download-item',

  props: {
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
      poll: {
        hasFailed: false,
        url: ''
      }
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
    this.poll.hasFailed = this.hasFailed
    this.poll.url = this.url

    const checkStatus = setInterval(this.ajaxRequestDownloadStatus, 10);
  },

  methods: {
    ajaxRequestDownloadStatus () {
      axios.get(this.endpointPoll, this.paramsPoll)
        .then(response => {
          console.log(response)
          this.poll.hasFailed = response.data.hasFailed
          this.poll.url = response.data.url
        })
        .catch(error => {

        })

      if(this.isReady) { clearInterval(checkStatus) }
    },

    deleteItem () {
      this.$emit('click:delete', this.id)
    }
  }
}
</script>