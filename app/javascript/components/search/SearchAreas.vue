<template>
  <div class="search--results-areas">
    <div class="search__bar">
      <div class="search__bar-content">
        <filter-trigger
          :is-disabled="isFilterPaneDisabled"
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
          :is-disabled="isMapPaneDisabled"
          :text="textMap"
          v-on:toggle:map-pane="toggleMapPane"
        />

        <download
          class="download--search"
          :text="textDownload"
        />
      </div>
    </div>

    <div 
      v-show="isMapPaneActive"
      class="search__map-container"
    >
      <slot name="map"/>
    </div>

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
          class="tabs--search-areas"
          :defaultSelectedId="tabIdDefault"
          :preSelectedId="tabIdSelected"
          v-on:click:tab="updateSelectedTab"
        />

        <search-areas-results
          :no-results-text="noResultsText"
          :results="newResults"
          :sm-trigger-element="smTriggerElement"
          v-on:request-more="requestMore"
          v-on:reset-pagination="resetPagination"
          v-show="!loadingResults"
        />

        <span :class="['icon--loading-spinner margin-center search__spinner', { 'icon-visible': loadingResults } ]" />
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
    },
    results: {
      type: Object,
      required: true
    }
  },

  data () {
    return {
      config: {
        queryStringParams: ['search_term', 'geo_type'],
        queryStringParamsFilters: ['db_type', 'is_type', 'special_status', 'designation', 'governance', 'iucn_category']
      },
      activeFilterOptions: [],
      filterGroupsWithPreSelected: [],
      isFilterPaneActive: false,
      isFilterPaneDisabled: false,
      isMapPaneActive: false,
      isMapPaneDisabled: false,
      loadingResults: false,
      newResults: this.results, // { geo_type: String, title: String, total: Number, areas: [{ areas: String, country: String, image: String, region: String, title: String, url: String }
      searchTerm: '',
      tabIdDefault: this.tabs[2].id,
      tabIdSelected: this.tabs[2].id
    }
  },

  created () {
    this.handleQueryString()
  },

  computed: {
    hasResults () {
      return this.newResults.length > 0
    }
  },

  methods: {
    ajaxSubmission (resetFilters=false, pagination=false, requestedPage=1) {
      if(!pagination) { this.loadingResults = true }

      let data = {
        params: {
          filters: this.activeFilterOptions,
          items_per_page: 9,
          requested_page: requestedPage,
          search_term: this.searchTerm,
          geo_type: this.tabIdSelected
        }
      }

      this.axiosSetHeaders()
      
      axios.get(this.endpointSearch, data)
        .then(response => {
          if(pagination){
            this.newResults.areas = this.newResults.areas.concat(response.data.areas.areas)
          } else {
            this.updateProperties(response, resetFilters)
          }

          this.loadingResults = false
        })
        .catch(function (error) {
          console.log('error', error)
        })
    },

    disableFilters () {
      this.isFilterPaneActive = false
      this.isFilterPaneDisabled = true
    },

    disableMap () {
      this.isFilterPaneActive = false
      this.isMapPaneDisabled = true
      this.isMapPaneActive = false
    },

    enableFilters () {
      this.isFilterPaneDisabled = false
    },

    enableMap () {
      this.isMapPaneDisabled = false
    },

    getFilteredSearchResults() {
      this.ajaxSubmission()
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
    
      if(params.includes('search_term')) {
        this.searchTerm = paramsFromUrl.get('search_term')
      }

      if(params.includes('geo_type')) { 
        this.tabIdSelected = paramsFromUrl.get('geo_type')
      }

      let filterParams = []

      this.config.queryStringParamsFilters.forEach(param => {
        if(paramsFromUrl.has(`filters[${param}][]`)) { filterParams.push(param) }
      })

      if(paramsFromUrl.has('filters[location][type]')) { filterParams.push('location[type]') }
      if(paramsFromUrl.has('filters[location][options][]')) { filterParams.push('location[options]') }
      
      this.filterGroups.map(filterGroup => {
        return filterGroup.filters.map(filter => {
          filterParams.forEach(key => {
            if(filter.id == key){
              filter.preSelected = paramsFromUrl.getAll(`filters[${key}][]`)
            }
            
            if(filter.id == 'location' && key == 'location[type]') { 
              filter.preSelected = [{
                type: paramsFromUrl.get('filters[location][type]'),
                options: paramsFromUrl.getAll('filters[location][options][]')
              }]
            }
          })

          return filter
        })
      })
      
      this.filterGroupsWithPreSelected = this.filterGroups

      this.updateDisabledComponents('site')
    },

    updateDisabledComponents (selectedTabId) {
      if(selectedTabId == 'site') {
        this.enableFilters()
        this.enableMap()
      } else {
        this.disableFilters()
        this.disableMap()
      }
    },

    updateFilters (filters) {
      this.$eventHub.$emit('reset:pagination')
      this.activeFilterOptions = filters
      this.getFilteredSearchResults()
      this.updateQueryString({ filters: filters })
    },

    updateProperties (response, resetFilters) {
      this.newResults = response.data.areas
      
      if(resetFilters) this.filterGroupsWithPreSelected = response.data.filters
    },

    updateQueryString (params) {
      let searchParams = new URLSearchParams(window.location.search)

      const key = Object.keys(params)[0]

      if(key == 'filters') {
        const filters = params.filters

        Object.keys(filters).forEach(key => {
          let queryKey = `filters[${key}][]`
          let queryValues = filters[key]
          
          if(key == 'location') {
            this.updateQueryStringParam(searchParams, 'filters[location][type]', filters[key].type)

            queryKey = 'filters[location][options][]'
            queryValues = filters[key].options
          }

          if(searchParams.has(queryKey)) { searchParams.delete(queryKey) }
          
          queryValues.forEach(value => {
            searchParams.append(queryKey, value)
          })
        })
      }

      if(key == 'search_term') {
        searchParams = new URLSearchParams()

        this.updateQueryStringParam(searchParams, key, params[key])
        this.updateQueryStringParam(searchParams, 'geo_type', 'site')
      }

      if(key == 'geo_type') {
        this.updateQueryStringParam(searchParams, key, params[key])
      }

      const newUrl = `${window.location.pathname}?${searchParams.toString()}`

      window.history.pushState({ query: 1 }, null, newUrl)
    },

    updateQueryStringParam (params, key, value) {
      params.has(key) ? params.set(key, value) : params.append(key, value)
    },

    updateSelectedTab (selectedTabId) {
      this.updateDisabledComponents(selectedTabId)
      this.tabIdSelected = selectedTabId
      this.resetPagination()
      this.getFilteredSearchResults()
      this.updateQueryString({ geo_type: selectedTabId })
    },

    updateSearchTerm (searchParams) {
      this.resetFilters()
      this.resetPagination()
      this.resetSearchTerm(searchParams)
      this.resetTabs()
      this.ajaxSubmission(true)
      this.updateQueryString({ search_term: searchParams.search_term })
    },

    requestMore (requestedPage) {
      this.ajaxSubmission(false, true, requestedPage)
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
      this.tabIdSelected = this.tabIdDefault
      this.$eventHub.$emit('reset:tabs')
    },

    toggleFilterPane () {
      this.isFilterPaneActive = !this.isFilterPaneActive
    },

    toggleMapPane () {
      this.isMapPaneActive = !this.isMapPaneActive
      if (this.isMapPaneActive) {
        this.$nextTick(() => {
          this.$eventHub.$emit('map:resize')
        })
      }
    }
  }
}
</script>
