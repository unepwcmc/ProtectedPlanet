<template>
  <div 
    class="search__results"
  >
    <div
      v-show="hasResults" 
      sm-trigger-element="test"
    >
      <listing-page-list-news
        v-for="item, index in results.items"
        :key="item._uid"
        :date="item.date"
        :image="item.image"
        :summary="item.summarye"
        :title="item.title"
        :url="item.url"
      />

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
import ListingPageListNews from '../listing/ListingPageListNews.vue'
import PaginationInfinityScroll from '../pagination/PaginationInfinityScroll.vue'

export default {
  name: 'listing-page-list',

  components: { 
    ListingPageListNews,
    PaginationInfinityScroll
  },
  
  props: {
    results: {
      type: Object // { title: String, total: Number, items: [{ date: String, image: String, summary: String, title: String, url: String }
    },
    smTriggerElement: {
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