<template>
  <div class="search--results-areas">
    <search-areas-input-autocomplete
      :endpoint="endpointAutocomplete"
      :types="autocompleteAreaTypes"
      v-on:submit-search="updateSearchTerm"
    />
  </div>
</template>

<script>
import axios from 'axios'
import mixinAxiosHelpers from '../../mixins/mixin-axios-helpers'
import SearchAreasInputAutocomplete from '../search/SearchAreasInputAutocomplete.vue'

export default {
  name: 'search-areas-home',

  components: { SearchAreasInputAutocomplete },

  mixins: [ mixinAxiosHelpers ],

  props: {
    autocompleteAreaTypes: {
      type: Array, // [ { name: String, options: [ { id: Number, name: String } ] } ]
      required: true
    },
    endpointAutocomplete: {
      type: String,
      required: true
    },
    endpointSearch: {
      type: String,
      required: true
    }
  },

  data () {
    return {
      areaType: '',
      searchTerm: '',
    }
  },

  methods: {
    ajaxSubmission () {
      this.axiosSetHeaders()

      let endpoint = this.endpointSearch

      endpoint = endpoint.replace('SEARCHTERM', this.searchTerm)
      endpoint = endpoint.replace('TYPE', this.areaType)

      axios.get(endpoint)
        .then(response => {
          console.log('success', response)
        })
        .catch(function (error) {
          console.log(error)
        })
    },

    updateSearchTerm (searchParams) {
      this.areaType = searchParams.type
      this.searchTerm = searchParams.search_term
      this.ajaxSubmission()
    }
  }
}
</script>