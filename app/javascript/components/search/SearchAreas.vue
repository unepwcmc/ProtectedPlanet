<template>
  <div class="search--results-areas">
    <div class="search__bar">
      <div class="search__bar-content">
        <filter-trigger
          :text="textFilters"
          v-on:toggle:filter-pane="toggleFilterPane"
        />

        <search-areas-input-autocomplete
          :config="configAutocomplete"
          :endpoint="endpointAutocomplete"
          :pre-populated-search-term="searchTerm"
          v-on:submit-search="updateSearchTerm"
        />

        <map-trigger
          :text="textMap"
          v-on:toggle-map-pane="toggleMapPane"
        />

        <download
          :text="textDownload"
        />
      </div>
    </div>

    <map-search
      class="search__map"
      :is-active="isMapPaneActive"
    />

    <div class="search__main">
      <filters-search
        class="search__filters"
        :filter-close-text="filterCloseText"
        :filterGroups="filterGroupsWithPreSelected"
        :is-active="isFilterPaneActive"
        :title="textFilters"
        v-on:update:filter-group="updateFilters"
        v-on:toggle:filter-pane="toggleFilterPane"
      />
      <div class="search__results">
        <tabs-fake
          :children="tabs"
          class="flex flex-h-center"
          v-on:click:tab="updateSelectedTab"
        />

        <search-areas-results
          :no-results-text="noResultsText"
          :results="results"
          :sm-trigger-element="smTriggerElement"
          v-on:request-more="requestMore"
          v-on:reset-pagination="resetPagination"
          v-show="!loadingResults"
        />

        <span :class="['icon--loading-spinner margin-center', { 'icon-visible': loadingResults } ]" />
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'
import mixinAxiosHelpers from '../../mixins/mixin-axios-helpers'
import Download from '../download/Download.vue'
import FilterTrigger from '../filters/FilterTrigger.vue'
import FiltersSearch from '../filters/FiltersSearch.vue'
import MapTrigger from '../map/MapTrigger.vue'
import MapSearch from '../map/MapSearch.vue'
import SearchAreasInputAutocomplete from '../search/SearchAreasInputAutocomplete.vue'
import SearchAreasResults from '../search/SearchAreasResults.vue'
import TabsFake from '../tabs/TabsFake.vue'

export default {
  name: 'search-areas',

  components: {
    Download,
    FilterTrigger,
    FiltersSearch,
    MapTrigger,
    MapSearch,
    SearchAreasInputAutocomplete,
    SearchAreasResults,
    TabsFake
  },

  mixins: [ mixinAxiosHelpers ],

  props: {
    configAutocomplete: {
      required: true,
      type: Object // { id: String, placeholder: String }
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
    filterCloseText: {
      type: String,
      required: true
    },
    filterGroups: {
      type: Array, // [ { title: String, filters: [ { id: String, name: String, title: String, options: [ { id: String, title: String }], type: String } ] } ]
      required: true
    },
    items_per_page: {
      type: Number,
      default: 9
    },
    query: {
      type: String
    },
    noResultsText: {
      required: true,
      type: String
    },
    smTriggerElement: {
      required: true,
      type: String
    },
    tabs: {
      required: true,
      type: Array // [{ id: String, title: String }]
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
    }
  },

  data () {
    return {
      config: {
        queryStringParams: ['db_type', 'is_type', 'special_status', 'designation', 'governance', 'iucn_category', 'location_id']
      },
      activeFilterOptions: [],
      filterGroupsWithPreSelected: [],
      isFilterPaneActive: false,
      isMapPaneActive: false,
      loadingResults: false,
      results: {}, // { geo_type: String, title: String, total: Number, areas: [{ areas: String, country: String, image: String, region: String, title: String, url: String }
      searchTerm: '',
      selectedTab: ''
    }
  },

  created () {
    if(this.query) { this.searchTerm = this.query }

    this.handleQueryString()
  },

  mounted () {
    this.getSearchResults()
  },

  computed: {
    hasResults () {
      return this.results.length > 0
    }
  },

  methods: {
    getSearchResults() {
      this.ajaxSubmission(true)
    },

    getFilteredSearchResults() {
      this.ajaxSubmission()
    },

    ajaxSubmission (resetFilters=false) {
      this.loadingResults = true

      let data = {
        params: {
          filters: this.activeFilterOptions,
          items_per_page: 9,
          requested_page: 1,
          search_term: this.searchTerm,
          geo_type: this.selectedTab
        }
      }

      console.log('data', data.params.filters)
      this.axiosSetHeaders()

      axios.get(this.endpointSearch, data)
        .then(response => {
          this.updateProperties(response, resetFilters)
          this.loadingResults = false
        })
        .catch(function (error) {
          console.log('error', error)
        })
    },

    /**
     * If a query string is present in the URL,
     * Initialise the state of the component based on its parameters
     * @see created()
     */
    handleQueryString () {
      const paramsFromUrl = new URLSearchParams(window.location.search)

      let params = []

      this.config.queryStringParams.forEach(param => {
        if(paramsFromUrl.has(param)) { params.push(param) }
      })
      
      this.filterGroups.map(filterGroup => {
        return filterGroup.filters.map(filter => {
          params.forEach(key => {
            if(key == 'location_id') { 
              if(filter.id == 'location') { 
                filter.preSelected = [{
                  id: paramsFromUrl.get('location_id'),
                  type: paramsFromUrl.get('location_type')
                }]
              }
            } else {
              if(filter.id == key) { 
                filter.preSelected = paramsFromUrl.getAll(key)
              }
            }
          })

          return filter
        })
      })
      
      this.filterGroupsWithPreSelected = this.filterGroups
    },

    updateFilters (filters) {
      this.$eventHub.$emit('reset:pagination')
      this.activeFilterOptions = filters
      this.getFilteredSearchResults()
    },

    updateProperties (response, resetFilters) {
      this.results = response.data.areas
      // TODO @Stacy Country/Region filters don't seem to be updating correctly after the first search
      if(resetFilters) this.filterGroupsWithPreSelected = response.data.filters
    },

    updateSelectedTab (selectedTab) {
      this.selectedTab = selectedTab
      this.resetPagination()
      this.getFilteredSearchResults()
    },

    updateSearchTerm (searchParams) {
      this.resetFilters()
      this.resetPagination()
      this.resetSearchTerm(searchParams)
      this.resetTabs()
      this.getSearchResults()
    },

    requestMore (paginationParams) {
      let data = {
        params: {
          filters: this.activeFilterOptions,
          geo_type: paginationParams.geoType,
          items_per_page: this.items_per_page,
          requested_page: paginationParams.requestedPage,
          search_term: this.searchTerm
        }
      }

      axios.get(this.endpointPagination, data)
        .then(response => {
          this.results.areas = this.results.areas.concat(response.data.areas)
        })
        .catch(function (error) {
          console.log(error)
        })
    },

    resetFilters () {
      this.activeFilterOptions = []
      this.$eventHub.$emit('reset:filter-options')
    },

    resetPagination () {
      this.$eventHub.$emit('reset:pagination')
    },

    resetSearchTerm (searchParams) {
      this.searchTerm = searchParams.search_term
    },

    resetTabs () {
      this.$eventHub.$emit('reset:tabs')
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
