<template>
  <div>
    <div class="container flex flex-v-center">
      <button>filter button</button>

      <button>map</button>

      <button>download</button>
    </div>

    <div class="container">
      <filters-search />

      <div class="search--results-areas">
        <div>
          <h2>title(<!--{{ totalItems }}-->)</h2>
          <button>View All</button>
        </div>
        <div class="cards--search-results-areas">
          <card-search-result-area
            v-for="result, index in results.regions"
            :key="index"
            :image="result.image"
            :summary="result.summary"
            :title="result.title"
            :url="result.url"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'
import { setCsrfToken } from '../../helpers/request-helpers'
import CardSearchResultArea from '../card/CardSearchResultArea.vue'
import FiltersSearch from '../filters/FiltersSearch.vue'

export default {
  name: 'SearchResultsAreas',

  components: { CardSearchResultArea, FiltersSearch },

  props: {
    endpoint: {
      type: String,
      required: true
    },
    // items_per_page: {
    //   type: Number,
    //   default: 15
    // },
    // noResultsText: {
    //   type: String,
    //   required: true
    // },
    // resultsText: {
    //   type: String,
    //   required: true
    // }
  },

  data () {
    return {
      categoryId: '',
      categories: [], // [ String ]
      currentPage: 0,
      // defaultCategory: this.categories[0].id,
      defaultPage: 1,
      pageItemsStart: 0,
      pageItemsEnd: 0,
      requestedPage: 0,
      // results: {}, // { regions: [{ title: String, url: String}], countries: [{ areas: String, region: String, title: String, url: String}], sites: [{ areas: String, country: String, image: String, region: String, title: String, url: String}] }
      searchTerm: '',
      totalItems: 0,
      results: { 
        regions: [
          {
            title: 'Asia & Pacific',
            url: 'url to page'
          }
        ],
        countries: [
          {
            areas: 5908,
            region: 'America',
            title: 'United States of America',
            url: 'url to page'
          },
          {
            areas: 508,
            regions: 'Europe',
            title: 'United Kingdom',
            url: 'url to page'
          },
          {
            areas: 508,
            regions: 'Europe',
            title: 'United Kingdom',
            url: 'url to page'
          },
          {
            areas: 508,
            regions: 'Europe',
            title: 'United Kingdom',
            url: 'url to page'
          }
        ],
        sites: [
          {
            country: 'France',
            image: 'url to generated map of PA location',
            region: 'Europe',
            title: 'Avenc De Fra Rafel',
            url: 'url to page'
          }
        ]
      }
    }
  },

  created () {
    // this.categoryId = this.defaultCategory
    // this.requestedPage = this.defaultPage
    // this.ajaxSubmission()
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

    changePage (newPage) {
      this.categoryId = this.defaultCategory
      this.requestedPage = newPage
    },

    updateCategory (categoryId) {
      this.categoryId = categoryId
      this.requestedPage = this.defaultPage
    },

    updateProperties (data) {
      this.categories = data.categories
      this.currentPage = data.current_page
      this.pageItemsStart = data.page_items_start
      this.pageItemsEnd = data.page_items_end
      this.results = data.results
      this.searchTerm = data.search_term
      this.totalItems = data.total_items
    },
  }
}
</script>