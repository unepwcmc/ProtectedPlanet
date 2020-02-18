<template>
  <div>
    <div>
      <h2>{{ title }} ({{ total }})</h2>
      
      <pagination-more
        text="View more"
        v-on:request-more="requestMore"
      />
    </div>
    <div class="cards--search-results-areas">
      <card-search-result-area
        v-for="area, index in areas"
        :key="index"
        :image="area.image"
        :summary="area.summary"
        :title="area.title"
        :url="area.url"
      />
    </div>
  </div>
</template>

<script>
import CardSearchResultArea from '../card/CardSearchResultArea.vue'
import PaginationMore from '../pagination/PaginationMore.vue'

export default {
  name: 'search-results-area',

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
    }
  }
}
</script>