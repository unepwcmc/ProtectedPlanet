<template>
  <div>
    <search-site-input
      :placeholder="placeholder"
      :popout="true"
      v-on:submit:search="updateSearchTerm"
    />
  </div>
</template>
<script>
import SearchSiteInput from './SearchSiteInput.vue'

export default {
  name: 'search-site-topbar',

  components: { SearchSiteInput },

  props: {
    endpoint: {
      required: true,
      type: String
    },
    placeholder: {
      required: true,
      type: String
    }
  },

  data () {
    return {
      searchTerm: '',
    }
  },

  methods: {
    ajaxSubmission () {
      const endpoint = this.endpoint + this.searchTerm

      window.location.href = endpoint
    },

    updateSearchTerm (searchTerm) {
      this.searchTerm = searchTerm
      this.ajaxSubmission()
    },
  }
}  
</script>