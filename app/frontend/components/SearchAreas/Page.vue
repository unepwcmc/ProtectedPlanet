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
      <FiltersPanel
        class="ct-search-areas-page__filters"
        :filterCloseText="textClose"
        :filters
        :filtersTitle
        :gaId
        :isActive="isFilterPaneActive"
        modifier="search-areas"
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
          v-show="!isReplacingResults"
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
import FiltersPanel from '@/components/Filters/Panel/Index.vue'
import FiltersTrigger from '@/components/Filters/Trigger.vue'
import IconLoadingSpinner from '@/components/Icon/LoadingSpinner.vue'
import SearchAreasInputAutocomplete from '@/components/SearchAreas/InputAutocomplete.vue'
import SearchAreasResults from '@/components/SearchAreas/Results/Index.vue'
import TabStrip from '@/components/TabStrip/Index.vue'
import Download from '@/components/Download/Index.vue'
import { getJson } from '@/lib/http'
import { useDownloadStore } from '@/stores/useDownloadStore'
import type { FilterGroupSelection, SearchAreasPageProps, SearchAreasResults as SearchAreasResultsData, SearchFilter, SearchFilterGroup } from '@/types/backend'

type SearchAreasPage = SearchAreasPageProps
const props = defineProps<SearchAreasPage>()

const QUERY_STRING_PARAMS = ['search_term', 'geo_type']
const QUERY_STRING_PARAMS_FILTERS = ['db_type', 'is_type', 'special_status', 'designation', 'governance', 'iucn_category']

const downloadStore = useDownloadStore()

// The hero partial renders an empty #vw-hero-search-target for this bar to
// teleport into, so it sits inside the hero while the rest of the tree stays at
// the mount point below. Renders in place when no hero target exists (tests).
const hasHeroSearchTarget = ref(false)
onMounted(() => {
  hasHeroSearchTarget.value = document.querySelector('#vw-hero-search-target') !== null
})

const activeFilterOptions = ref<Record<string, unknown>>({})
// Search::FiltersSerializer#serialize is a hardcoded single-element array, not
// a real multi-group structure, so flatten it once here and let the rest of the
// tree work with a plain filter list.
const filtersTitle = props.filterGroups[0]?.title ?? ''
const filters = ref<SearchFilter[]>(props.filterGroups[0]?.filters ?? [])
const isFilterPaneActive = ref(false)
const isFilterPaneDisabled = ref(false)
const isLoadingResults = ref(false)
// Pagination appends to the list, so the current cards stay put under the
// spinner; every other request replaces them and should show the spinner alone.
const isReplacingResults = ref(false)
const newResults = ref<SearchAreasResults>(props.results)
const searchTerm = ref('')
const tabIdDefault = props.tabs[2].id
const tabIdSelected = ref(tabIdDefault)
// Vue 3 has no global event bus: bumping these props down the Filters/Results
// trees stands in for the old 'reset:filter-options'/'reset:pagination'
// broadcasts.
const filterResetKey = ref(0)
const paginationResetKey = ref(0)

const isDownloadDisabled = computed(() => Number(newResults.value.total || 0) === 0)

interface SearchAreasResultsResponse {
  areas: SearchAreasResultsData
  filters: SearchFilterGroup[]
}

async function ajaxSubmission(resetFilters = false, pagination = false, requestedPage = 1) {
  isLoadingResults.value = true
  isReplacingResults.value = !pagination

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
  isReplacingResults.value = false
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

// Initialise from the URL's query params, if any — called at the end of setup.
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

  const activeFromUrl: Record<string, unknown> = {}

  filters.value = (props.filterGroups[0]?.filters ?? []).map((filter) => {
    const updatedFilter = { ...filter }
    delete updatedFilter.preSelected

    filterParams.forEach((key) => {
      if (filter.id === key) {
        updatedFilter.preSelected = paramsFromUrl.getAll(`filters[${key}][]`)
        activeFromUrl[filter.id] = updatedFilter.preSelected
      }
      if (filter.id === 'location' && key === 'location[type]') {
        updatedFilter.preSelected = [{
          type: paramsFromUrl.get('filters[location][type]') ?? '',
          options: paramsFromUrl.getAll('filters[location][options][]')
        }]
        activeFromUrl[filter.id] = updatedFilter.preSelected[0]
      }
    })

    return updatedFilter
  })

  // The panel only mounts when it is opened, and its groups emit their
  // URL-preselected value on mount. Recording that value here keeps the emit a
  // no-op in updateFilters, so opening the panel does not re-run the search.
  activeFilterOptions.value = activeFromUrl
  // useDownloadStore#searchFilters is typed `unknown[]`, but what
  // Download/Index.vue forwards to the endpoint is this
  // `{ [filterId]: options }` dict.
  downloadStore.updateSearchFilters(activeFromUrl as unknown as unknown[])
}

function updateDisabledComponents(selectedTabId: string) {
  if (selectedTabId === 'site') enableFilters()
  else disableFilters()
}

// FiltersPanel reports one group at a time; the accumulated dict is what the
// endpoint, the query string and the download store all take.
function updateFilters(payload: { id: string, options: FilterGroupSelection }) {
  // Groups re-announce their selection on mount and when resetKey bumps, so
  // opening the panel or switching tab would otherwise fire a second, identical
  // request. Only a genuine change gets through.
  if (isUnchanged(payload.id, payload.options)) return

  paginationResetKey.value += 1
  const filters = { ...activeFilterOptions.value, [payload.id]: payload.options }
  activeFilterOptions.value = filters
  updateQueryString({ filters })
  // Re-syncs the active filters and the download store from the query string.
  handleQueryString()
  getFilteredSearchResults()
}

function isUnchanged(id: string, options: FilterGroupSelection) {
  return JSON.stringify(activeFilterOptions.value[id] ?? []) === JSON.stringify(options)
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
    // Switching tab clears every filter, so rebuild the query string from
    // scratch and keep only the search term alongside the new geo_type.
    const currentSearchTerm = searchParams.get('search_term')
    searchParams = new URLSearchParams()

    if (currentSearchTerm) updateQueryStringParam(searchParams, 'search_term', currentSearchTerm)
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
  resetFilters()
  resetPagination()
  updateQueryString({ geo_type: selectedTabId })
  // Drops the preSelected values the filter list was initialised with, now
  // that the filter params are gone from the query string.
  handleQueryString()
  getFilteredSearchResults()
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
  downloadStore.updateSearchFilters({} as unknown as unknown[])
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
  py-6
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
