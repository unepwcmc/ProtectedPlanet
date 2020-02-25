<template>
  <div>
    <search 
      :endpoint="endpoint"
      :placeholder="placeholder"
      v-on:submit:search="updateSearchTerm"
    />
    
    <tabs-fake 
      :children="categories"
      v-on:click:tab="updateCategory" 
    />

    <search-results
      :results="results"
      :resultsText="resultsText"
      :totalItems="totalItems"
    />

    <pagination 
      :currentPage="currentPage"
      :pageItemsEnd="pageItemsEnd" 
      :pageItemsStart="pageItemsStart" 
      :noResultsText="noResultsText"
      :totalItems="totalItems"
      v-on:update:page="updatePage"
    />
  </div>
</template>
<script>
import axios from 'axios'
import mixinAxiosHelpers from '../../mixins/mixin-axios-helpers'
import Pagination from '../pagination/Pagination.vue'
import Search from './Search.vue'
import SearchResults from './SearchResults.vue'
import TabsFake from '../tabs/TabsFake.vue'

export default {
  name: 'search-site',

  components: { Pagination, Search, SearchResults, TabsFake },

  mixins: [ mixinAxiosHelpers ],

  props: {
    categories: {
      required: true,
      type: Array // [ { id: Number, title: String } ] 
    },
    endpoint: {
      required: true,
      type: String
    },
    itemsPerPage: {
      default: 15,
      type: Number
    },
    noResultsText: {
      required: true,
      type: String
    },
    placeholder: {
      required: true,
      type: String
    },
    resultsText: {
      required: true,
      type: String
    }
  },

  data () {
    return {
      categoryId: '',
      currentPage: 0,
      defaultCategory: this.categories[0].id,
      defaultPage: 1,
      pageItemsStart: 0,
      pageItemsEnd: 0,
      requestedPage: 1,
      results: [], // [ { title: String, url: String, summary: String, image: 'String' } ]
      searchTerm: '',
      totalItems: 0,
    }
  },

  mounted () {
    this.categoryId = this.defaultCategory
  },

  mounted () { 
    // this.ajaxSubmission()
  },

  methods: {
    ajaxSubmission () {
      let data = {
        category_id: this.categoryId,
        items_per_page: this.itemsPerPage,
        requested_page: this.requestedPage,
        search_term: this.searchTerm
      }

      this.axiosSetHeaders()

      axios.post(this.endpoint, data)
        .then(response => {
          console.log('success', response)
          this.updateProperties(response.data)
        })
        .catch(function (error) {
          console.log(error)
        })
    },

    resetAll () {
      this.categoryId = this.defaultCategory
      this.requestedPage = this.defaultPage
      this.$eventHub.$emit('reset-search')
    },

    updateCategory (categoryId) {
      this.categoryId = categoryId
      this.requestedPage = this.defaultPage
      this.ajaxSubmission()
    },

    updatePage (requestedPage) {
      this.requestedPage = requestedPage
      this.ajaxSubmission()
    },

    updateProperties (data) {
      this.currentPage = data.current_page
      this.pageItemsStart = data.page_items_start
      this.pageItemsEnd = data.page_items_end
      this.results = data.results
      this.searchTerm = data.search_term
      this.totalItems = data.total_items
    },

    updateSearchTerm (searchTerm) {
      this.resetAll()
      this.searchTerm = searchTerm
      this.ajaxSubmission()
    },
  }
}  
</script>