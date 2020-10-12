<template>
  <div 
    class="listing__results"
  >
    <div
      v-show="hasResults" 
      sm-trigger-element="test"
    >
      <template v-if="template == 'news'">
        <div class="listing__cards-news">
          <listing-page-card-news
            v-for="results, index in results.results"
            :key="results._uid"
            :date="results.date"
            :image="results.image"
            :summary="results.summary"
            :title="results.title"
            :url="results.url"
          />
        </div>
      </template>

      <template v-if="template == 'resources'">
        <div class="listing__cards-resources">
          <listing-page-card-resources
            v-for="result, index in results.results"
            :key="result._uid"
            :date="result.date"
            :fileUrl="result.fileUrl"
            :linkTitle="result.linkTitle"
            :linkUrl="result.linkUrl"
            :summary="result.summary"
            :title="result.title"
            :url="result.url"
          />
        </div>
      </template>

      <pagination-infinity-scroll 
        v-if="smTriggerElement" 
        :smTriggerElement="smTriggerElement"
        :total="results.total"
        :total-pages="results.totalPages"
        v-on:request-more="requestMore"
      />
    </div>

    <p 
      v-show="!hasResults"
      v-html="textNoResults"
      class="search__results-none"
    />
  </div>
</template>

<script>
import ListingPageCardNews from '../listing/ListingPageCardNews.vue'
import ListingPageCardResources from '../listing/ListingPageCardResources.vue'
import PaginationInfinityScroll from '../pagination/PaginationInfinityScroll.vue'

export default {
  name: 'listing-page-list',

  components: { 
    ListingPageCardNews,
    ListingPageCardResources,
    PaginationInfinityScroll
  },
  
  props: {
    results: {
      type: Object // { title: String, total: Number, results: [{ date: String, image: String, summary: String, title: String, url: String }
    },
    smTriggerElement: {
      required: true,
      type: String
    },
    template: {
      required: true,
      type: String
    },
    textNoResults: {
      required: true,
      type: String
    }
  },

  computed: {
    hasResults () {
      return this.results.total > 0
    }
  },

  methods: {
    requestMore (paginationParams) {
      this.$emit('request-more', paginationParams)
    }
  }
}
</script>