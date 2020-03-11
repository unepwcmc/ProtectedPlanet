<template>
  <div 
    class="search__results"
  >
    <search-areas-geo-type
      v-show="hasResults" 
      v-for="result, index in results"
      :key="index"
      :areas="result.areas"
      :geo-type="result.geoType"
      :sm-trigger-element="uniqueSmTriggerElement(result.geoType)"
      :total="result.total"
      :total-pages="result.totalPages"
      :title="result.title"
      v-on:request-more="requestMore"
    />

    <p 
      v-show="!hasResults"
      v-html="noResultsText"
      class="search__results-none"
    />
  </div>
</template>

<script>
import SearchAreasGeoType from '../search/SearchAreasGeoType.vue'

export default {
  name: 'search-areas-results',

  components: { 
    SearchAreasGeoType 
  },
  
  props: {
    noResultsText: {
      required: true,
      type: String
    },
    results: {
      type: Array
    },
    smTriggerElement: {
      required: true,
      type: String
    }
  },

  computed: {
    hasResults () {
      let totalResults = 0

      this.results.map( result => totalResults = totalResults + result.total )

      return totalResults > 0
    }
  },

  methods: {
    requestMore (paginationParams) {
      this.$emit('request-more', paginationParams)
    },
    
    uniqueSmTriggerElement (geoType) {
      return `${this.smTriggerElement}-${geoType}`
    }
  }
}
</script>