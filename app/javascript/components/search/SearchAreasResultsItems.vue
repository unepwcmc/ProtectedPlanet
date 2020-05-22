<template>
  <div>
    <div class="search__results-bar">
      <h2>{{ results.title }} ({{ results.total }})</h2>
      
<!--       <pagination-more
        :sm-trigger-element="smTriggerElement"
        text="View All"
        :total="total"
        :total-pages="totalPages"
        v-on:request-more="requestMore"
        v-on:reset-pagination="resetPagination"
      /> -->
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

    <span v-if="smTriggerElement" :class="smTriggerElement"></span>
  </div>
</template>

<script>
import CardSearchResultArea from '../card/CardSearchResultArea.vue'
import PaginationMore from '../pagination/PaginationMore.vue'

export default {
  name: 'search-areas-results-items',

  components: { CardSearchResultArea, PaginationMore },

  props: {
    results: {
      required: true,
      type: Object // { geo_type: String, title: String, total: Number, totalPages: Number, areas: [{ areas: String, country: String, image: String, region: String, title: String, url: String }
    },
    currentPage: {
      default: 1,
      type: Number
    },
    smTriggerElement: {
      required: true,
      type: String
    }
  },

  methods: {
    requestMore (requestedPage) {
      const params = {
        geoType: this.geoType,
        requestedPage: requestedPage
      }

      this.$emit('request-more', params)
    },

    resetPagination (geoType) {
      this.$emit('reset-pagination', this.geoType)
    }
  }
}
</script>