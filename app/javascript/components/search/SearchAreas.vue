<template>
  <div class="search--results-areas">
    <div class="search__bar">
      <div class="search__bar-content">
        <filter-trigger
          :text="textFilters"
          v-on:toggle-filter-pane="toggleFilterPane"
        />

        <search-areas-input-autocomplete
          :endpoint="endpointAutocomplete"
          :types="autocompleteAreaTypes"
          v-on:submit-search="updateSearchTerm"
        />

        <map-trigger
          :text="textMap"
          v-on:toggle-map-pane="toggleMapPane"
        />

        <download-trigger
          :text="textDownload"
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
        <search-areas-results
          :results="results"
          v-on:request-more="requestMore"
        />
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'
import mixinAxiosHelpers from '../../mixins/mixin-axios-helpers'
import DownloadTrigger from '../download/DownloadTrigger.vue'
import FilterTrigger from '../filters/FilterTrigger.vue'
import FiltersSearch from '../filters/FiltersSearch.vue'
import MapTrigger from '../map/MapTrigger.vue'
import MapSearch from '../map/MapSearch.vue'
import SearchAreasInputAutocomplete from '../search/SearchAreasInputAutocomplete.vue'
import SearchAreasResults from '../search/SearchAreasResults.vue'

export default {
  name: 'search-areas',

  components: {
    DownloadTrigger,
    FilterTrigger,
    FiltersSearch,
    MapTrigger,
    MapSearch,
    SearchAreasInputAutocomplete,
    SearchAreasResults
  },

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
    query: {
      type: String
    },
    textDownload: {
      type: String,
      required: true
    },
    textFilters: {
      type: String,
      required: true
    },
    textMap: {
      type: String,
      required: true
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

  mounted () {
    if(this.query) {
      console.log('here')
      this.searchTerm = this.query
      this.ajaxSubmission()
    }
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
          area_type: this.areaType,
          filters: this.activeFilterOptions,
          items_per_page: this.itemsPerPage,
          search_term: this.searchTerm
        }
      }

      this.axiosSetHeaders()

      axios.get(this.endpointSearch, data)
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
      this.results = []
      // data
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
          search_term: this.searchTerm
        }
      }

      axios.post(this.endpointPagination, data)
        .then(response => {
          this.data.results.find(object => object.geo_type === paginationParams.geoType).areas.concat(data.results);
        })
        .catch(function (error) {
          console.log(error)
        })
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
