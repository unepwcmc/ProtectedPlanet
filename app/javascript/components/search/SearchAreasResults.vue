<template>
  <div 
    class="search__results"
  >
    <search-areas-results-items
      v-show="hasResults" 
      sm-trigger-element="test"
      :areas="results.areas"
      :geo-type="results.geoType"
      :total="results.total"
      :total-pages="results.totalPages"
      :title="results.title"
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
      type: Object
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