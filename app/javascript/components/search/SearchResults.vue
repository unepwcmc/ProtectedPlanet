<template>
  <div class="search--results">
    <tabs-fake v-on:tab-clicked="updateCategory" :children="categories"></tabs-fake>
    
    <p class="search__total">({{ totalItems }} results)</p>

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

    <pagination 
      :currentPage="currentPage"
      :pageItemsEnd="pageItemsEnd" 
      :pageItemsStart="pageItemsStart" 
      :noResultsText="noResultsText"
      :totalItems="totalItems">
    </pagination>
  </div>
</template>

<script>
import axios from 'axios'
import { setCsrfToken } from '../../helpers/request-helpers'
import CardSearchResult from '../card/CardSearchResult.vue'
import Pagination from '../pagination/Pagination.vue'
import TabsFake from '../tabs/TabsFake.vue'

export default {
  name: 'SearchResults',

  components: { CardSearchResult, Pagination, TabsFake },

  props: {
    endpoint: {
      type: String,
      required: true
    },
    items_per_page: {
      type: Number,
      default: 15
    },
    noResultsText: {
      type: String,
      required: true
    }
  },

  data () {
    return {
      categoryId: '',
      categories: [], // [ String ]
      currentPage: 1,
      pageItemsStart: 1,
      pageItemsEnd: 10,
      requestedPage: 1,
      results: [], // [ { title: String, url: String, summary: String, image: 'String' } ]
      searchTerm: '',
      totalItems: 45,
      totalPages: 3,
    }
  },

  created () {
    this.categoryId = this.categories[0].id
    this.ajaxSubmission()
  },

  computed: {
    hasResults () {
      return this.results.length > 0
    }
  },

  methods: {
    ajaxSubmission () {
      let data = {
        params: {
          category_id: this.categoryId,
          items_per_page: this.itemsPerPage,
          requested_page: this.requestedPage,
          searchTerm: this.searchTerm
        }
      }

      axios.post(this.endpoint, data)
        .then(response => {
          this.updateProperties(response.data)
        })
        .catch(function (error) {
          console.log(error)
        })
    },

    updateCategory (categoryId) {
      this.categoryId = categoryId
    },

    updateProperties (data) {
      this.categories = data.categories
      this.currentPage = data.current_page
      this.pageItemsStart = data.page_items_start
      this.pageItemsEnd = data.page_items_end
      this.results = data.results
      this.searchTerm = data.search_term
      this.totalItems = data.total_items
      this.totalPages = data.total_pages
    },
  }
}
</script>