<template>
  <div>
    <div class="container flex flex-v-center">
      <button>filter button</button>
      
      <search-autocomplete-types
        :endpoint-autocomplete="endpointAutocomplete"
        :types="autocompleteAreaTypes"
        v-on:submit-search="updateSearchTerm"
      />

      <button>map</button>

      <button>download</button>
    </div>

    <div class="container">
      <filters-search />

      <search-results-area 
        v-for="result, index in data.results"
        class="search--results-areas"
        :areas="result.areas"
        :geo-type="result.geo_type"
        :total="result.total"
        :title="result.title"
        v-on:request-more="requestMore"
      />
    </div>
  </div>
</template>

<script>
import axios from 'axios'
import { setCsrfToken } from '../../helpers/request-helpers'
import FiltersSearch from '../filters/FiltersSearch.vue'
import SearchAutocompleteTypes from '../search/SearchAutocompleteTypes.vue'
import SearchResultsArea from '../search/SearchResultsArea.vue'

export default {
  name: 'SearchResultsAreas',

  components: { FiltersSearch, SearchAutocompleteTypes, SearchResultsArea },

  props: {
    autocompleteAreaTypes: {
      type: Array, // [ { name: String, options: [ { id: Number, name: String } ] } ]
      required: true
    },
    endpointAutocomplete: {
      type: String,
      required: true
    },
    endpointPagination: {
      type: String,
      required: true
    },
    endpointSearch: {
      type: String,
      required: true
    },
    items_per_page: {
      type: Number,
      default: 3
    },
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
      areaType: '',
      currentPage: 0,
      defaultPage: 1,
      pageItemsStart: 0,
      pageItemsEnd: 0,
      requestedPage: 0,
      // results: {}, // { regions: [{ title: String, url: String}], countries: [{ areas: String, region: String, title: String, url: String}], sites: [{ areas: String, country: String, image: String, region: String, title: String, url: String}] }
      searchTerm: '',
      totalItems: 0,
      data: {
        results: [
          {
            geo_type: 'region',
            title: 'Regions',
            total: 10,
            areas: [
              {
                title: 'Asia & Pacific',
                url: 'url to page'
              }
            ]
          },
          {
            geo_type: 'country',
            title: 'Countries',
            total: 10,
            areas: [
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
            ]
          },
          {
            geo_type: 'site',
            title: 'Protected Areas',
            total: 30,
            areas: [
              {
                country: 'France',
                image: 'url to generated map of PA location',
                region: 'Europe',
                title: 'Avenc De Fra Rafel',
                url: 'url to page'
              }
            ]
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
    ajaxSubmission (callback) {
      let data = {
        params: {
          type: this.type,
          items_per_page: this.itemsPerPage,
          requested_page: this.requestedPage,
          searchTerm: this.searchTerm
        }
      }

      axios.post(this.endpointSearch, data)
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

    updateSearchTerm (searchParams) {
      console.log('updateSearchTerm', searchParams)
      this.areaType = searchParams.type
      this.searchTerm = searchParams.search_term
      this.ajaxSubmission()
    },

    requestMore (paginationParams) {
      let data = {
        params: {
          area_type: this.areaType,
          geo_type: paginationParams.geoType,
          items_per_page: 6,
          requested_page: paginationParams.requestedPage,
          searchTerm: this.searchTerm
        }
      }

      console.log('data', data)

      axios.post(this.endpointPagination, data)
        .then(response => {
          this.data.results.find(object => object.geo_type === 'paginationParams.geoType').areas.concat(data.results);
        })
        .catch(function (error) {
          console.log(error)
        })


      // this.ajaxRequest((data) => { this.results = this.results.concat(data.items) })
    }
  }
}
</script>