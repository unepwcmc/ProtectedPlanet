<template>
  <div class="listing">
    <div class="listing__bar">
      <div class="listing__bar-content">
        <FiltersTrigger
          class="listing__filters-trigger"
          :text="textFilterTrigger"
          @toggle:filterPane="toggleFilterPane"
        />
      </div>
    </div>
    <div class="listing__main">
      <ListingFiltersPanel
        class="listing__filters"
        :filterCloseText="textFiltersClose"
        :filterGroups
        :gaId
        :isActive="isFilterPaneActive"
        :preSelected="preSelectedFilters"
        :textClear
        :title="textFilterTrigger"
        @toggle:filterPane="toggleFilterPane"
        @update:filterGroup="updateFilters"
      />
      <div class="listing__results-wrapper">
        <ListingList
          v-show="!updatingResults"
          :resetKey="paginationResetKey"
          :results="currentResults"
          :template
          :textNoResults
          @requestMore="requestMore"
        />
        <span
          class="icon--loading-spinner margin-center listing__spinner"
          :class="{ 'icon-visible': loadingResults }"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { getJson } from '@/lib/http'
import { QUERY_STRING_FILTER_IDS } from '@/constants/listing'
import FiltersTrigger from '@/components/Filters/Trigger.vue'
import ListingFiltersPanel from '@/components/Listing/FiltersPanel.vue'
import ListingList from '@/components/Listing/List.vue'
import type { ListingProps, ListingResults } from '@/types/backend'

type Listing = ListingProps
const props = defineProps<Listing>()

const currentResults = ref<ListingResults>(props.results)
const activeFilterOptions = ref<Record<string, Array<string | number>>>({})
const isFilterPaneActive = ref(false)
const loadingMoreResults = ref(false)
const updatingResults = ref(false)
const paginationResetKey = ref(0)
let ajaxRequests = 0

const loadingResults = computed(() => loadingMoreResults.value || updatingResults.value)

const preSelectedFilters = readPreSelectedFiltersFromUrl()

function readPreSelectedFiltersFromUrl(): Record<string, string[]> {
  const params = new URLSearchParams(window.location.search)
  const preSelected: Record<string, string[]> = {}

  QUERY_STRING_FILTER_IDS.forEach((id) => {
    const values = params.getAll(`filters[${id}][]`)
    if (values.length) preSelected[id] = values
  })

  return preSelected
}

function toggleFilterPane() {
  isFilterPaneActive.value = !isFilterPaneActive.value
}

function buildSearchParams(requestedPage: number): URLSearchParams {
  const query = new URLSearchParams()

  Object.entries(activeFilterOptions.value).forEach(([key, values]) => {
    values.forEach(value => query.append(`filters[${key}][]`, String(value)))
  })
  query.append('filters[ancestor]', String(props.pageId))
  query.set('items_per_page', String(props.itemsPerPage ?? 6))
  query.set('requested_page', String(requestedPage))
  query.set('search_index', 'cms')

  return query
}

function requestSearch(pagination = false, requestedPage = 1) {
  if (pagination) loadingMoreResults.value = true
  else updatingResults.value = true

  ajaxRequests++

  getJson<ListingResults>(props.endpointSearch, buildSearchParams(requestedPage))
    .then((data) => {
      currentResults.value = pagination
        ? { ...data, results: currentResults.value.results.concat(data.results) }
        : data
    })
    .catch((error) => {
      console.error(error)
    })
    .finally(() => {
      ajaxRequests--

      if (ajaxRequests === 0) {
        window.setTimeout(() => {
          loadingMoreResults.value = false
          updatingResults.value = false
        }, 1000)
      }
    })
}

function requestMore(requestedPage: number) {
  requestSearch(true, requestedPage)
}

function updateFilters(filters: Record<string, Array<string | number>>) {
  paginationResetKey.value++
  activeFilterOptions.value = filters
  requestSearch()
  updateQueryString(filters)
}

function updateQueryString(filters: Record<string, Array<string | number>>) {
  const searchParams = new URLSearchParams(window.location.search)

  Object.entries(filters).forEach(([key, values]) => {
    const queryKey = `filters[${key}][]`
    searchParams.delete(queryKey)
    values.forEach(value => searchParams.append(queryKey, String(value)))
  })

  const newUrl = `${window.location.pathname}?${searchParams.toString()}`
  window.history.replaceState({ page: 1 }, '', newUrl)
}
</script>
