<template>
  <div>
    <div class="search__results-bar">
      <h2>{{ results.title }} ({{ results.total }})</h2>
    </div>
    <div class="cards--search-results-areas">
      <card-search-result-area
        v-for="area, index in results.areas"
        :key="index"
        :country-flag="area.countryFlag"
        :geo-type="results.geoType"
        :image="area.image"
        :total-areas="area.totalAreas"
        :title="area.title"
        :url="area.url"
      />
    </div>

    <pagination-infinity-scroll 
      v-if="smTriggerElement" 
      :smTriggerElement="smTriggerElement"
      :total="results.total"
      :total-pages="results.totalPages"
      v-on:request-more="requestMore"
    />
  </div>
</template>

<script>
import CardSearchResultArea from '../card/CardSearchResultArea.vue'
import PaginationInfinityScroll from '../pagination/PaginationInfinityScroll.vue'

export default {
  name: 'search-areas-results-items',

  components: { CardSearchResultArea, PaginationInfinityScroll },

  props: {
    results: {
      required: true,
      type: Object // { geo_type: String, title: String, total: Number, totalPages: Number, areas: [{ areas: String, country: String, image: String, region: String, title: String, url: String }
    },
    smTriggerElement: {
      required: true,
      type: String
    }
  },

  methods: {
    requestMore (requestedPage) {
      this.$emit('request-more', requestedPage)
    }
  }
}
</script>