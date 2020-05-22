<template>
  <div 
    class="search__results"
  >
    <search-areas-results-items
      v-show="hasResults" 
      sm-trigger-element="test"
      :results="results"
      v-on:request-more="requestMore"
      v-on:reset-pagination="resetPagination"
    />

    <p 
      v-show="!hasResults"
      v-html="noResultsText"
      class="search__results-none"
    />
  </div>
</template>

<script>
import SearchAreasResultsItems from '../search/SearchAreasResultsItems.vue'

export default {
  name: 'search-areas-results',

  components: { 
    SearchAreasResultsItems 
  },
  
  props: {
    noResultsText: {
      required: true,
      type: String
    },
    results: {
      type: Object // { geo_type: String, title: String, total: Number, areas: [{ areas: String, country: String, image: String, region: String, title: String, url: String }
    },
    smTriggerElement: {
      required: true,
      type: String
    }
  },

  computed: {
    hasResults () {
      // let totalResults = 0

      // this.results.map( result => totalResults = totalResults + result.total )

      return this.results.total > 0
    }
  },

  methods: {
    requestMore (paginationParams) {
      this.$emit('request-more', paginationParams)
    },

    resetPagination (geoType) {
      this.$emit('reset-pagination', geoType)
    },
    
    uniqueSmTriggerElement (geoType) {
      return `${this.smTriggerElement}-${geoType}`
    }
  }
}
</script>