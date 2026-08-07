<template>
  <div class="search--results-areas">
    <div class="search__bar">
      <div class="search__bar-content">
        <FiltersTrigger
          class="search__filter-trigger"
          :isDisabled="isFilterPaneDisabled"
          :text="textFilters"
          @toggle:filterPane="toggleFilterPane"
        />
        <SearchAreasInputAutocomplete
          :config="configAutocomplete"
          :endpoint="endpointAutocomplete"
          :prePopulatedSearchTerm="searchTerm"
          @submit:search="updateSearchTerm"
        />
        <Download
          :buttonText="downloadButtonText"
          class="download--search"
          :downloadDisabled
          :gaId
          :options="downloadOptions"
          :textCommercial="downloadTextCommercial"
        />
      </div>
    </div>
    <div class="search__main">
      <SearchAreasFiltersPanel
        class="search__filters"
        :filterCloseText="textClose"
        :filterGroups="filterGroupsWithPreSelected"
        :gaId
        :isActive="isFilterPaneActive"
        :textClear
        :title="textFilters"
        :resetKey="filterResetKey"
        @update:filterGroup="updateFilters"
        @toggle:filterPane="toggleFilterPane"
      />
      <div class="search__results">
        <SearchAreasTabStrip
          :children="tabs"
          class="tabs--search-areas"
          :defaultSelectedId="tabIdDefault"
          :gaId
          :preSelectedId="tabIdSelected"
          @click:tab="updateSelectedTab"
        />
        <SearchAreasResults
          v-show="!loadingResults"
          :noResultsText
          :results="newResults"
          :smTriggerElement
          :resetKey="paginationResetKey"
          @requestMore="requestMore"
        />
        <span
          class="icon--loading-spinner margin-center search__spinner"
          :class="{ 'icon-visible': loadingResults }"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import FiltersTrigger from '@/components/Filters/Trigger.vue'
import SearchAreasFiltersPanel from '@/components/SearchAreas/FiltersPanel.vue'
import SearchAreasInputAutocomplete from '@/components/SearchAreas/InputAutocomplete.vue'
import SearchAreasResults from '@/components/SearchAreas/Results/Index.vue'
import SearchAreasTabStrip from '@/components/SearchAreas/TabStrip/Index.vue'
import Download from '@/components/Download/Index.vue'
import { getJson } from '@/lib/http'
import { useDownloadStore } from '@/stores/useDownloadStore'
import type { SearchAreasPageProps, SearchAreasResults as SearchAreasResultsData, SearchFilterGroup } from '@/types/backend'

type SearchAreasPage = SearchAreasPageProps
const props = defineProps<SearchAreasPage>()

const QUERY_STRING_PARAMS = ['search_term', 'geo_type']
const QUERY_STRING_PARAMS_FILTERS = ['db_type', 'is_type', 'special_status', 'designation', 'governance', 'iucn_category']

const downloadStore = useDownloadStore()

const activeFilterOptions = ref<Record<string, unknown>>({})
const filterGroupsWithPreSelected = ref<SearchFilterGroup[]>(props.filterGroups)
const isFilterPaneActive = ref(false)
const isFilterPaneDisabled = ref(false)
const loadingResults = ref(false)
const newResults = ref<SearchAreasResultsData>(props.results)
const searchTerm = ref('')
const tabIdDefault = props.tabs[2].id
const tabIdSelected = ref(tabIdDefault)
// Replace the legacy $eventHub 'reset:filter-options'/'reset:pagination'
// broadcasts — bumping these props down the Filters/Results trees stands in
// for the global bus (removed in Vue 3, see 14-architecture-and-design.md).
const filterResetKey = ref(0)
const paginationResetKey = ref(0)

const downloadDisabled = computed(() => Number(newResults.value.total || 0) === 0)

interface SearchAreasResultsResponse {
  areas: SearchAreasResultsData
  filters: SearchFilterGroup[]
}

async function ajaxSubmission(resetFilters = false, pagination = false, requestedPage = 1) {
  if (!pagination) loadingResults.value = true

  const response = await getJson<SearchAreasResultsResponse>(props.endpointSearch, {
    filters: JSON.stringify(activeFilterOptions.value),
    items_per_page: '9',
    requested_page: String(requestedPage),
    search_term: searchTerm.value,
    geo_type: tabIdSelected.value
  })

  if (pagination) {
    newResults.value = { ...newResults.value, areas: [...newResults.value.areas, ...response.areas.areas] }
  }
  else {
    updateProperties(response, resetFilters)
  }

  loadingResults.value = false
}

function disableFilters() {
  isFilterPaneActive.value = false
  isFilterPaneDisabled.value = true
}

function enableFilters() {
  isFilterPaneDisabled.value = false
}

function getFilteredSearchResults() {
  ajaxSubmission()
}

function getQueryStringParams(paramsFromUrl: URLSearchParams) {
  return QUERY_STRING_PARAMS.filter(param => paramsFromUrl.has(param))
}

// If a query string is present in the URL, initialise the state of the
// component based on its parameters — see the top-level call below.
function handleQueryString() {
  const paramsFromUrl = new URLSearchParams(window.location.search)
  const params = getQueryStringParams(paramsFromUrl)

  if (params.includes('search_term')) {
    const urlSearchTerm = paramsFromUrl.get('search_term') ?? ''
    searchTerm.value = urlSearchTerm
    downloadStore.updateSearchTerm(urlSearchTerm)
  }

  if (params.includes('geo_type')) {
    const urlTabIdSelected = paramsFromUrl.get('geo_type') ?? tabIdDefault
    tabIdSelected.value = urlTabIdSelected
    updateDisabledComponents(urlTabIdSelected)
  }

  const filterParams: string[] = []

  QUERY_STRING_PARAMS_FILTERS.forEach((param) => {
    if (paramsFromUrl.has(`filters[${param}][]`)) filterParams.push(param)
  })

  if (paramsFromUrl.has('filters[location][type]')) filterParams.push('location[type]')
  if (paramsFromUrl.has('filters[location][options][]')) filterParams.push('location[options]')

  filterGroupsWithPreSelected.value = props.filterGroups.map(filterGroup => ({
    ...filterGroup,
    filters: filterGroup.filters.map((filter) => {
      const updatedFilter = { ...filter }
      delete updatedFilter.preSelected

      filterParams.forEach((key) => {
        if (filter.id === key) {
          updatedFilter.preSelected = paramsFromUrl.getAll(`filters[${key}][]`)
        }
        if (filter.id === 'location' && key === 'location[type]') {
          updatedFilter.preSelected = [{
            type: paramsFromUrl.get('filters[location][type]') ?? '',
            options: paramsFromUrl.getAll('filters[location][options][]')
          }]
        }
      })

      return updatedFilter
    })
  }))
}

function updateDisabledComponents(selectedTabId: string) {
  if (selectedTabId === 'site') enableFilters()
  else disableFilters()
}

function updateFilters(filters: Record<string, unknown>) {
  paginationResetKey.value += 1
  activeFilterOptions.value = filters
  getFilteredSearchResults()
  updateQueryString({ filters })
  handleQueryString()
  // useDownloadStore#searchFilters is typed `unknown[]` from its Vuex-module
  // port (Wave 4), but the actual payload Download/Index.vue forwards to the
  // download endpoint is this `{ [filterId]: options }` dict — same shape the
  // legacy window.__downloadStoreBridge passed through untouched.
  downloadStore.updateSearchFilters(filters as unknown as unknown[])
}

function updateProperties(response: SearchAreasResultsResponse, resetFilters: boolean) {
  newResults.value = response.areas
  if (resetFilters) filterGroupsWithPreSelected.value = response.filters
}

type QueryStringUpdate = { filters: Record<string, unknown> } | { search_term: string } | { geo_type: string }

function updateQueryString(params: QueryStringUpdate) {
  let searchParams = new URLSearchParams(window.location.search)

  if ('filters' in params) {
    Object.entries(params.filters).forEach(([key, value]) => {
      let queryKey = `filters[${key}][]`
      let queryValues = value as string[] | { type: string, options: string[] }

      if (key === 'location') {
        const location = queryValues as { type: string, options: string[] }
        updateQueryStringParam(searchParams, 'filters[location][type]', location.type)

        queryKey = 'filters[location][options][]'
        queryValues = location.options
      }

      if (searchParams.has(queryKey)) searchParams.delete(queryKey)

      ;(queryValues as string[]).forEach((value) => {
        searchParams.append(queryKey, value)
      })
    })
  }

  if ('search_term' in params) {
    searchParams = new URLSearchParams()

    updateQueryStringParam(searchParams, 'search_term', params.search_term)
    updateQueryStringParam(searchParams, 'geo_type', 'site')
  }

  if ('geo_type' in params) {
    updateQueryStringParam(searchParams, 'geo_type', params.geo_type)
  }

  const newUrl = `${window.location.pathname}?${searchParams.toString()}`

  window.history.replaceState({ page: 1 }, '', newUrl)
}

function updateQueryStringParam(params: URLSearchParams, key: string, value: string) {
  if (params.has(key)) params.set(key, value)
  else params.append(key, value)
}

function updateSelectedTab(selectedTabId: string) {
  updateDisabledComponents(selectedTabId)
  tabIdSelected.value = selectedTabId
  resetPagination()
  getFilteredSearchResults()
  updateQueryString({ geo_type: selectedTabId })
}

function updateSearchTerm(newSearchTerm: string) {
  resetFilters()
  resetPagination()
  searchTerm.value = newSearchTerm
  ajaxSubmission(true)
  updateQueryString({ search_term: newSearchTerm })
  downloadStore.updateSearchTerm(newSearchTerm)
}

function requestMore(requestedPage: number) {
  ajaxSubmission(false, true, requestedPage)
}

function resetFilters() {
  activeFilterOptions.value = {}
  filterResetKey.value += 1
}

function resetPagination() {
  paginationResetKey.value += 1
}

function toggleFilterPane() {
  isFilterPaneActive.value = !isFilterPaneActive.value
}

handleQueryString()
</script>
