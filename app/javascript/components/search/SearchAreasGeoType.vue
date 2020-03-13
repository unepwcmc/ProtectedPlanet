<template>
  <div>
    <div class="search__results-bar">
      <h2>{{ title }} ({{ total }})</h2>
      
      <pagination-more
        :sm-trigger-element="smTriggerElement"
        text="View All"
        :total="total"
        :total-pages="totalPages"
        v-on:request-more="requestMore"
        v-on:reset-pagination="resetPagination"
      />
    </div>
    <div class="cards--search-results-areas">
      <card-search-result-area
        v-for="area, index in areas"
        :key="index"
        :country-flag="area.countryFlag"
        :geo-type="geoType"
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
  name: 'search-areas-geo-type',

  components: { CardSearchResultArea, PaginationMore },

  props: {
    areas: {
      required: true,
      type: Array
    },
    geoType: {
      required: true,
      type: String
    },
    currentPage: {
      default: 1,
      type: Number
    },
    total: {
      required: true,
      type: Number
    },
    totalPages: {
      required: true,
      type: Number
    },
    smTriggerElement: {
      required: true,
      type: String
    },
    title: {
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