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
import axios from 'axios'
import mixinAxiosHelpers from '../../mixins/mixin-axios-helpers'
import SearchSiteInput from './SearchSiteInput.vue'

export default {
  name: 'search-site-topbar',

  components: { SearchSiteInput },

  mixins: [ mixinAxiosHelpers ],

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
      this.axiosSetHeaders()

      const endpoint = this.endpoint + this.searchTerm

      axios.get(endpoint)
        .then(response => {
          console.log('success')
        })
        .catch(function (error) {
          console.log(error)
        })
    },

    updateSearchTerm (searchTerm) {
      this.searchTerm = searchTerm
      this.ajaxSubmission()
    },
  }
}  
</script>