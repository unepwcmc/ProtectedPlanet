<template>
  <li>
    <span class="modal__li-title">{{ title }}</span>

    <span 
      class="modal__li-failed"
      v-show="hasFailed"
    >Download Failed</span>

    <span 
      class="modal__li-generating"
      v-show="isGenerating"
    >Generating...</span>

    <a 
      class="modal__li-download"
      :href="url"  
      v-show="isReady"
    >Download</a>

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
    title: {
      type: String
    },
    url: {
      type: String
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

  methods: {
    deleteItem () {
      this.$emit('click:delete', this.id)
    }
  }
}
</script>