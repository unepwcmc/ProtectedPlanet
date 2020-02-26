<template>
  <div 
    v-show="hasResults" 
    class="search__results"
  >
    <search-areas-geo-type
      v-for="result, index in results"
      :key="index"
      :areas="result.areas"
      :geo-type="result.geoType"
      :total="result.total"
      :title="result.title"
      v-on:request-more="requestMore"
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
    results: {
      type: Array
    }
  },

  computed: {
    hasResults () {
      return this.results.length > 0
    }
  },

  methods: {
    requestMore (paginationParams) {
      this.$emit('request-more', paginationParams)
    }
  }
}
</script>