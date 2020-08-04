<template>
  <div 
    class="listing__results"
  >
    <div
      v-show="hasResults" 
      sm-trigger-element="test"
    >
      <template v-if="template == 'news'">
        <div class="listing__cards cards--articles">
          <listing-page-list-news
            v-for="card, index in results.cards"
            :key="card._uid"
            :date="card.date"
            :image="card.image"
            :summary="card.summary"
            :title="card.title"
            :url="card.url"
          />
        </div>
      </template>

      <template v-if="template == 'resources'">
        <div class="listing__cards-resources cards--resources">
          <listing-page-list-resources
            v-for="card, index in results.cards"
            :key="card._uid"
            :date="card.date"
            :fileUrl="card.fileUrl"
            :linkTitle="card.linkTitle"
            :linkUrl="card.linkUrl"
            :summary="card.summary"
            :title="card.title"
            :url="card.url"
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
import ListingPageListNews from '../listing/ListingPageListNews.vue'
import ListingPageListResources from '../listing/ListingPageListResources.vue'
import PaginationInfinityScroll from '../pagination/PaginationInfinityScroll.vue'

export default {
  name: 'listing-page-list',

  components: { 
    ListingPageListNews,
    ListingPageListResources,
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