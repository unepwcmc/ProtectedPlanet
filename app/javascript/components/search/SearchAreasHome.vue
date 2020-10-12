<template>
  <div class="search--home">
    <search-areas-input-autocomplete
      :config="config"
      :endpoint="endpointAutocomplete"
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
    config: {
      required: true,
      type: Object // { id: String, placeholder: String }
    },
    endpointAutocomplete: {
      required: true,
      type: String
    },
    endpointSearch: {
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
      let endpoint = this.endpointSearch

      endpoint = endpoint.replace('SEARCHTERM', this.searchTerm)
      endpoint = endpoint.replace('TYPE', this.config.id)
      
      window.location.href = endpoint
    },

    updateSearchTerm (searchParams) {
      this.searchTerm = searchParams.search_term
      this.ajaxSubmission()
    }
  }
}
</script>
