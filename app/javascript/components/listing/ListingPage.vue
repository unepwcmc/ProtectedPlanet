<template>
  <div>
    <div class="listing__bar">
      <div class="listing__bar-content">
        <filter-trigger
          class="listing__filters-trigger"
          :text="textFilterTrigger"
          v-on:toggle:filter-pane="toggleFilterPane"
        />
    </div>
    </div>

    <div class="listing__main">
      <filters-search
        class="listing__filters"
        :filter-close-text="textFiltersClose"
        :filter-groups="filterGroupsWithPreSelected"
        :is-active="isFilterPaneActive"
        :title="textFilterTrigger"
        v-on:update:filter-group="updateFilters"
        v-on:toggle:filter-pane="toggleFilterPane"
      />
      
      <listing-page-list
        :results="newResults"
        :sm-trigger-element="smTriggerElement"
        :template="template"
        :text-no-results="textNoResults"
        v-on:request-more="requestMore"
        v-on:reset-pagination="resetPagination"
        v-show="!loadingResults"
      />
    </div>
  </div>
</template>

<script>
import axios from 'axios'
import mixinAxiosHelpers from '../../mixins/mixin-axios-helpers'
import FilterTrigger from '../filters/FilterTrigger.vue'
import FiltersSearch from '../filters/FiltersSearch.vue'
import ListingPageList from '../listing/ListingPageList.vue'

export default {
  name: 'ListingPage',

  components: { FilterTrigger, FiltersSearch, ListingPageList },
  
  mixins: [ mixinAxiosHelpers ],

  props: {
    endpointSearch: {
      required: true,
      type: String
    },
    filterGroups: {
      required: true,
      type: Array // [ { title: String, filters: [ { id: String, name: String, title: String, options: [ { id: String, title: String }], type: String } ] } ]
    },
    pageId: {
      required: true,
      type: Number
    },
    results: {
      required: true,
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
    textFiltersClose: {
      required: true,
      type: String
    },
    textFilterTrigger: {
      required: true,
      type: String
    },
    textNoResults: {
      required: true,
      type: String
    }
  },

  data () {
    return {
      config: {
        queryStringParams: [],
        queryStringParamsFilters: ['topics', 'types']
      },
      activeFilterOptions: [],
      filterGroupsWithPreSelected: [],
      isFilterPaneActive: false,
      loadingResults: false,
      newResults: this.results
    }
  },
  created () {
    this.handleQueryString()
    this.ajaxSubmission()
  },

  mounted() {
    this.filterGroupsWithPreSelected = this.filterGroups
  },

  methods: {
    ajaxSubmission (resetFilters=false, pagination=false, requestedPage=1) {
      if(!pagination) { this.loadingResults = true }

      let filters = {...this.activeFilterOptions, ...{ ancestor: this.pageId }}

      let data = {
        params: {
          filters: filters,
          items_per_page: 9,
          requested_page: requestedPage,
          search_index: 'cms'
        }
      }

      this.axiosSetHeaders()

      axios.get(this.endpointSearch, data)
        .then(response => {
          if(pagination){
            this.newResults.cards = this.newResults.results.concat(response.data.results)
          } else {
            this.updateProperties(response, resetFilters)
          }

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

      let filterParams = []

      this.config.queryStringParamsFilters.forEach(param => {
        if(paramsFromUrl.has(`filters[${param}][]`)) { filterParams.push(param) }
      })

      this.filterGroups.map(filterGroup => {
        return filterGroup.filters.map(filter => {
          filterParams.forEach(key => {
            if(filter.id == key){
              filter.preSelected = paramsFromUrl.getAll(`filters[${key}][]`)
            }
          })

          return filter
        })
      })
      
      this.filterGroupsWithPreSelected = this.filterGroups
    },

    getFilteredSearchResults() {
      this.ajaxSubmission()
    },

    requestMore (requestedPage) {
      this.ajaxSubmission(false, true, requestedPage)
    },

    resetPagination () {
      this.$eventHub.$emit('reset:pagination')
    },

    toggleFilterPane () {
      this.isFilterPaneActive = !this.isFilterPaneActive
    },

    updateFilters (filters) {
      console.log('updateFilters', filters)
      this.$eventHub.$emit('reset:pagination')
      this.activeFilterOptions = filters
      this.getFilteredSearchResults()
      this.updateQueryString({ filters: filters })
    },

    updateProperties (response, resetFilters) {
      this.newResults = response.data
      
      if(resetFilters) this.filterGroupsWithPreSelected = response.data.filters
    },

    updateQueryString (params) {
      let searchParams = new URLSearchParams(window.location.search)
      const key = Object.keys(params)[0]
  
      if(key == 'filters') {
        const filters = params.filters

        console.log('params.filters', params.filters)

        Object.keys(filters).forEach(key => {
          console.log('key', key)
          let queryKey = `filters[${key}][]`
          let queryValues = filters[key]
          
          if(searchParams.has(queryKey)) { searchParams.delete(queryKey) }
          
          queryValues.forEach(value => {
            console.log('append')
            searchParams.append(queryKey, value)
          })
        })
      }

      const newUrl = `${window.location.pathname}?${searchParams.toString()}`

      window.history.pushState({ query: 1 }, null, newUrl)
    }
  }
}
</script>

