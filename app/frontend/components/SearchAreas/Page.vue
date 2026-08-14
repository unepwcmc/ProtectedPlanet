<template>
  <div class="ct-search-areas-page">
    <Teleport
      to="#vw-hero-search-target"
      :disabled="!hasHeroSearchTarget"
    >
      <div class="ct-search-areas-page__bar">
        <div class="ct-search-areas-page__bar--left">
          <FiltersTrigger
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
        </div>
        <Download
          class="ct-search-areas-page__bar--right"
          :buttonText="downloadButtonText"
          :downloadDisabled="isDownloadDisabled"
          :gaId
          :options="downloadOptions"
          :textCommercial="downloadTextCommercial"
        />
      </div>
    </Teleport>
    <div class="ct-search-areas-page__main">
      <SearchAreasFiltersPanel
        class="ct-search-areas-page__filters"
        :filterCloseText="textClose"
        :filters
        :filtersTitle
        :gaId
        :isActive="isFilterPaneActive"
        :textClear
        :title="textFilters"
        :resetKey="filterResetKey"
        @update:filterGroup="updateFilters"
        @toggle:filterPane="toggleFilterPane"
      />
      <div class="ct-search-areas-page__results">
        <TabStrip
          class="ct-search-areas-page__strips"
          :children="tabs"
          :defaultSelectedId="tabIdDefault"
          :gaId
          :preSelectedId="tabIdSelected"
          @click:tab="updateSelectedTab"
        />
        <SearchAreasResults
          :noResultsText
          :results="newResults"
          :smTriggerElement
          :resetKey="paginationResetKey"
          @requestMore="requestMore"
        />
        <IconLoadingSpinner
          v-if="isLoadingResults"
          class="ct-search-areas-page__spinner"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import FiltersTrigger from '@/components/Filters/Trigger.vue'
import IconLoadingSpinner from '@/components/Icon/LoadingSpinner.vue'
import SearchAreasFiltersPanel from '@/components/SearchAreas/FiltersPanel/Index.vue'
import SearchAreasInputAutocomplete from '@/components/SearchAreas/InputAutocomplete.vue'
import SearchAreasResults from '@/components/SearchAreas/Results/Index.vue'
import TabStrip from '@/components/TabStrip/Index.vue'
import Download from '@/components/Download/Index.vue'
import { getJson } from '@/lib/http'
import { useDownloadStore } from '@/stores/useDownloadStore'
import type { SearchAreasPageProps, SearchAreasResults as SearchAreasResultsData, SearchFilter, SearchFilterGroup } from '@/types/backend'

type SearchAreasPage = SearchAreasPageProps
const props = defineProps<SearchAreasPage>()

const QUERY_STRING_PARAMS = ['search_term', 'geo_type']
const QUERY_STRING_PARAMS_FILTERS = ['db_type', 'is_type', 'special_status', 'designation', 'governance', 'iucn_category']

const downloadStore = useDownloadStore()

// The hero partial renders an empty #vw-hero-search-target for this bar to teleport
// into, so it visually sits inside the hero while the rest of this component's tree
// (filters panel, tabs, results) stays at its own mount point below. Falls back to
// rendering the bar in place when no hero target exists (e.g. component tests).
const hasHeroSearchTarget = ref(false)
onMounted(() => {
  hasHeroSearchTarget.value = document.querySelector('#vw-hero-search-target') !== null
})

const activeFilterOptions = ref<Record<string, unknown>>({})
// The backend always returns at most one filter group (Search::FiltersSerializer#serialize
// is a hardcoded single-element array, never a real multi-group structure) — flatten it here
// once so the rest of this component and the FiltersPanel tree work with a plain filter list.
const filtersTitle = props.filterGroups[0]?.title ?? ''
const filters = ref<SearchFilter[]>(props.filterGroups[0]?.filters ?? [])
const isFilterPaneActive = ref(false)
const isFilterPaneDisabled = ref(false)
const isLoadingResults = ref(false)
const newResults = ref<SearchAreasResultsData>(props.results)
const searchTerm = ref('')
const tabIdDefault = props.tabs[2].id
const tabIdSelected = ref(tabIdDefault)
// Replace the legacy $eventHub 'reset:filter-options'/'reset:pagination'
// broadcasts — bumping these props down the Filters/Results trees stands in
// for the global bus (removed in Vue 3, see 14-architecture-and-design.md).
const filterResetKey = ref(0)
const paginationResetKey = ref(0)

const isDownloadDisabled = computed(() => Number(newResults.value.total || 0) === 0)

interface SearchAreasResultsResponse {
  areas: SearchAreasResultsData
  filters: SearchFilterGroup[]
}

async function ajaxSubmission(resetFilters = false, pagination = false, requestedPage = 1) {
  isLoadingResults.value = true

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

  isLoadingResults.value = false
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

  filters.value = (props.filterGroups[0]?.filters ?? []).map((filter) => {
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
  if (resetFilters) filters.value = response.filters[0]?.filters ?? []
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

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-search-areas-page {
  @apply bg-theme-grey-xlight text-theme-grey-black;
}

.ct-search-areas-page__bar {
  @apply
  py-2
  tw-shared-base-container
  tw-shared-base-flex-gap-3-md-gap-6
  items-center
  justify-between;
}

.ct-search-areas-page__bar--left{
  @apply
  tw-shared-base-flex-gap-3-md-gap-6
  grow
  md:grow-0
  items-center
  md:justify-between
  md:w-4/5;
}

.ct-search-areas-page__main {
  @apply
  tw-shared-base-container
  tw-shared-base-flex-gap-6
  items-start;
}

.ct-search-areas-page__filters {
  @apply
  shrink-0
  pr-0
  md:w-1/3
  lg:w-[27.5%];
}

.ct-search-areas-page__results {
  @apply
  pt-6
  grow
  w-full
  min-h-75
  md:min-h-150
  tw-shared-base-flex-col-gap-6;
}

.ct-search-areas-page__strips {
  @apply self-center;
}

.ct-search-areas-page__spinner {
  @apply mx-auto my-13.75 size-10 text-black;
}
</style>
