<template>
  <div class="search--results-areas">
    <div class="search__bar">
      <div class="search__bar-content">
        <filter-trigger
          v-on:toggle-filter-pane="toggleFilterPane"
        />
        
        <search-autocomplete-types
          :endpoint-autocomplete="endpointAutocomplete"
          :types="autocompleteAreaTypes"
          v-on:submit-search="updateSearchTerm"
        />

        <map-trigger
          v-on:toggle-map-pane="toggleMapPane"
        />

        <button
          class="download__trigger"
          text="download"
        />
      </div>
    </div>
    
    <map-search 
      class="search__map"
      :isActive="isMapPaneActive"
    />

    <div class="search__main">
      <filters-search 
        class="search__filters"
        :filter-groups="filterGroups"
        :isActive="isFilterPaneActive"
        v-on:update:filter-group="updateFilters"
      />
      <div class="search__results">
        <search-geo-type
          v-for="result, index in results"
          :areas="result.areas"
          :geo-type="result.geo_type"
          :total="result.total"
          :title="result.title"
          v-on:request-more="requestMore"
        />
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'
import mixinAxiosHelpers from '../../mixins/mixin-axios-helpers'
import FilterTrigger from '../filters/FilterTrigger.vue'
import FiltersSearch from '../filters/FiltersSearch.vue'
import MapTrigger from '../map/MapTrigger.vue'
import MapSearch from '../map/MapSearch.vue'
import SearchAutocompleteTypes from '../search/SearchAutocompleteTypes.vue'
import SearchGeoType from '../search/SearchGeoType.vue'

export default {
  name: 'SearchResultsAreas',

  components: { FilterTrigger, FiltersSearch, MapTrigger, MapSearch, SearchAutocompleteTypes, SearchGeoType },

  mixins: [ mixinAxiosHelpers ],

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
    filterGroups: {
      type: Array, // [ { title: String, filters: [ { id: String, name: String, title: String, options: [ { id: String, title: String }], type: String } ] } ]
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
      activeFilterOptions: [],
      areaType: '',
      currentPage: 0,
      defaultPage: 1,
      isFilterPaneActive: true,
      isMapPaneActive: false,
      pageItemsStart: 0,
      pageItemsEnd: 0,
      requestedPage: 0,
      results: [], // { geo_type: String, title: String, total: Number, areas: [{ areas: String, country: String, image: String, region: String, title: String, url: String }] }]
      searchTerm: '',
      totalItems: 0,
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
          area_type: this.areaType,
          filters: this.activeFilterOptions,
          items_per_page: this.itemsPerPage,
          searchTerm: this.searchTerm
        }
      }

      this.axiosSetHeaders()

      axios.post(this.endpointSearch, data)
        .then(response => {
          console.log('success', response)
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

    updateFilters (filters) {
      console.log('update filters and do new search', filters)
      this.activeFilterOptions = filters
      this.ajaxSubmission()
    },

    updateProperties (data) {
      this.results = data
      // this.searchTerm = data.search_term
    },

    updateSearchTerm (searchParams) {
      this.resetAll()
      this.areaType = searchParams.type
      this.searchTerm = searchParams.search_term
      this.ajaxSubmission()
    },

    resetAll () {
      this.activeFilterOptions = []
      this.$eventHub.$emit('reset-search')
    },

    requestMore (paginationParams) {
      let data = {
        params: {
          area_type: this.areaType,
          filters: this.activeFilterOptions,
          geo_type: paginationParams.geoType,
          items_per_page: 6,
          requested_page: paginationParams.requestedPage,
          searchTerm: this.searchTerm
        }
      }

      console.log('data', data)

      axios.post(this.endpointPagination, data)
        .then(response => {
          this.data.results.find(object => object.geo_type === paginationParams.geoType).areas.concat(data.results);
        })
        .catch(function (error) {
          console.log(error)
        })


      // this.ajaxRequest((data) => { this.results = this.results.concat(data.items) })
    },

    toggleFilterPane () {
      this.isFilterPaneActive = !this.isFilterPaneActive
    },

    toggleMapPane () {
      this.isMapPaneActive = !this.isMapPaneActive
    }
  }
}
</script>