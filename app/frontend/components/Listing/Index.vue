<template>
  <div class="ct-listing">
    <div class="ct-listing__bar">
      <div class="ct-listing__bar-content">
        <FiltersTrigger
          :text="textFilterTrigger"
          @toggle:filterPane="toggleFilterPane"
        />
      </div>
    </div>
    <div class="ct-listing__main">
      <ListingFiltersPanel
        class="ct-listing__filters"
        :filterCloseText="textFiltersClose"
        :filters
        :filtersTitle
        :gaId
        :isActive="isFilterPaneActive"
        :preSelected="activeFilterOptions"
        :textClear
        :title="textFilterTrigger"
        @toggle:filterPane="toggleFilterPane"
        @update:filterGroup="updateFilters"
      />
      <div class="ct-listing__results-wrapper">
        <ListingList
          v-show="!updatingResults"
          :resetKey="paginationResetKey"
          :results="currentResults"
          :template
          :textNoResults
          @requestMore="requestMore"
        />
        <IconLoadingSpinner
          class="ct-listing__spinner"
          :class="{ 'ct-listing__spinner--visible': loadingResults }"
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
import IconLoadingSpinner from '@/components/Icon/LoadingSpinner.vue'
import ListingFiltersPanel from '@/components/Listing/FiltersPanel/Index.vue'
import ListingList from '@/components/Listing/List.vue'
import type { ListingProps, ListingResults } from '@/types/backend'

type Listing = ListingProps
const props = defineProps<Listing>()

// The backend always returns at most one filter group (CmsHelper#get_category_filters is a
// hardcoded single-element array, never a real multi-group structure) — flatten it here once
// so the FiltersPanel tree works with a plain filter list instead of looping over groups.
const filters = props.filterGroups[0]?.filters ?? []
const filtersTitle = props.filterGroups[0]?.title ?? ''

const currentResults = ref<ListingResults>(props.results)
// The URL query string is the single source of truth for active filters.
// activeFilterOptions is never mutated directly — it's always reassigned by
// re-reading the URL, so Vue state can't drift from what's in the address bar.
const activeFilterOptions = ref<Record<string, Array<string | number>>>(readFiltersFromUrl())
const isFilterPaneActive = ref(false)
const loadingMoreResults = ref(false)
const updatingResults = ref(false)
const paginationResetKey = ref(0)
let ajaxRequests = 0

const loadingResults = computed(() => loadingMoreResults.value || updatingResults.value)

function readFiltersFromUrl(): Record<string, string[]> {
  const params = new URLSearchParams(window.location.search)
  const filters: Record<string, string[]> = {}

  QUERY_STRING_FILTER_IDS.forEach((id) => {
    const values = params.getAll(`filters[${id}][]`)
    if (values.length) filters[id] = values
  })

  return filters
}

function writeFilterToUrl(id: string, options: Array<string | number>) {
  const searchParams = new URLSearchParams(window.location.search)
  const queryKey = `filters[${id}][]`

  searchParams.delete(queryKey)
  options.forEach(value => searchParams.append(queryKey, String(value)))

  const newUrl = `${window.location.pathname}?${searchParams.toString()}`
  window.history.replaceState({ page: 1 }, '', newUrl)
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

function updateFilters(payload: { id: string, options: Array<string | number> }) {
  paginationResetKey.value++
  writeFilterToUrl(payload.id, payload.options)
  activeFilterOptions.value = readFiltersFromUrl()
  requestSearch()
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-listing{
  @apply tw-shared-base-flex-col-gap-9-lg-no-gap;
}

.ct-listing__bar {
  @apply
  tw-shared-shadow-bottom-grey-light
  bg-white
  border-b
  border-solid
  border-theme-grey-light
  py-3
  tw-shared-base-flex-col-gap-3;
}

.ct-listing__bar-content {
  @apply
  tw-shared-base-container
  flex
  items-center;
}

.ct-listing__main {
  @apply
  tw-shared-base-container
  md:flex
  min-h-25
  md:min-h-150
  tw-shared-base-flex-gap-9;
}

.ct-listing__filters{
  @apply
  md:border-r
  md:w-1/4;
}

.ct-listing__results-wrapper {
  @apply
  grow
  md:pt-9
  md:w-3/4;
}

.ct-listing__spinner {
  @apply
  invisible
  mx-auto
  my-13.75
  size-10
  text-black;
}

.ct-listing__spinner--visible {
  @apply visible;
}
</style>
