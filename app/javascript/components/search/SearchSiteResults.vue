<template>
  <div class="search--results">
    <p 
      class="search__total"
      v-show="hasResults"
    >
      ({{ totalItems }} {{ resultsText }})
    </p>

    <div class="cards--search-results">
      <card-search-result
        v-for="result, index in results"
        :key="index"
        :image="result.image"
        :summary="result.summary"
        :title="result.title"
        :url="result.url"
      />
    </div>
  </div>
</template>

<script>
import CardSearchResult from '../card/CardSearchResult.vue'

export default {
  name: 'search-site-results',

  components: { CardSearchResult },

  props: {
    results: {
      type: Array // [ { title: String, url: String, summary: String, image: 'String' } ]
    },
    resultsText: {
      required: true,
      type: String
    },
    totalItems: {
      required: true,
      type: Number
    }
  },

  computed: {
    hasResults () {
      return this.results != undefined && this.results.length > 0
    }
  }
}
</script>