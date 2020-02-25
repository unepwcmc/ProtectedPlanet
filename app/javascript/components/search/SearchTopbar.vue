<template>
  <div>
    <search 
      :placeholder="placeholder"
      :popout="true"
      v-on:submit:search="updateSearchTerm"
    />
  </div>
</template>
<script>
import axios from 'axios'
import mixinAxiosHelpers from '../../mixins/mixin-axios-helpers'
import Search from './Search.vue'

export default {
  name: 'search-topbar',

  components: { Search },

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
      let data = {
        search_term: this.searchTerm
      }

      this.axiosSetHeaders()

      axios.post(this.endpoint, data)
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