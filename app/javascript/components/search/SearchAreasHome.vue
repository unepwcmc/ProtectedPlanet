<template>
  <div class="search--home">
    <search-areas-input-autocomplete
      :endpoint="endpointAutocomplete"
      :types="autocompleteAreaTypes"
      v-on:submit-search="updateSearchTerm"
    />
  </div>
</template>

<script>
import SearchAreasInputAutocomplete from '../search/SearchAreasInputAutocomplete.vue'

export default {
  name: 'search-areas-home',

  components: { SearchAreasInputAutocomplete },

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
      let endpoint = this.endpointSearch

      endpoint = endpoint.replace('SEARCHTERM', this.searchTerm)
      endpoint = endpoint.replace('TYPE', this.areaType)
      
      window.location.href = endpoint
    },

    updateSearchTerm (searchParams) {
      this.areaType = searchParams.type
      this.searchTerm = searchParams.search_term
      this.ajaxSubmission()
    }
  }
}
</script>
