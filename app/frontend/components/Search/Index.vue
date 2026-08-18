<template>
  <div class="ct-search-site">
    <SearchSiteInput
      :disabled="isLoadingResults"
      :placeholder
      :prePopulatedSearchTerm="searchTerm"
      @submit:search="updateSearchTerm"
    />
    <TabStrip
      :children="categories"
      :defaultSelectedId="defaultCategoryId"
      :disabled="isLoadingResults"
      :gaId
      :preSelectedId="categoryId"
      @click:tab="updateCategory"
    />
    <SearchResults
      v-show="!isLoadingResults"
      :results
      :resultsText
      :totalItems
    />
    <IconLoadingSpinner
      class="ct-search-site__spinner"
      :class="{ 'ct-search-site__spinner--visible': isLoadingResults }"
    />
    <SearchPagination
      :currentPage
      :loading="isLoadingResults"
      :noResultsText
      :pageItemsEnd
      :pageItemsStart
      :totalItems
      @update:page="updatePage"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import IconLoadingSpinner from '@/components/Icon/LoadingSpinner.vue'
import SearchSiteInput from '@/components/Search/SiteInput.vue'
import SearchPagination from '@/components/Search/Pagination.vue'
import SearchResults from '@/components/Search/Results/Index.vue'
import TabStrip from '@/components/TabStrip/Index.vue'
import { getJson } from '@/lib/http'
import type { SearchSiteProps, SearchSiteResultsData } from '@/types/backend'

type SearchSite = SearchSiteProps
const props = defineProps<SearchSite>()

enum UrlParams {
  SearchTerm = 'search_term'
}

const defaultCategoryId = props.categories[0].id

const categoryId = ref(defaultCategoryId)
const currentPage = ref(props.dataPageLoad.currentPage)
const isLoadingResults = ref(false)
const pageItemsEnd = ref(props.dataPageLoad.pageItemsEnd)
const pageItemsStart = ref(props.dataPageLoad.pageItemsStart)
const results = ref(props.dataPageLoad.results)
const searchTerm = ref(props.dataPageLoad.searchTerm)
const totalItems = ref(props.dataPageLoad.totalItems)

function resetCategory() {
  categoryId.value = defaultCategoryId
}

async function ajaxSubmission(requestedPage: number) {
  isLoadingResults.value = true

  const response = await getJson<SearchSiteResultsData>(props.endpoint, {
    filters: JSON.stringify({ ancestor: categoryId.value }),
    items_per_page: String(props.itemsPerPage ?? 15),
    requested_page: String(requestedPage),
    search_term: searchTerm.value
  })

  updateProperties(response)
  isLoadingResults.value = false
}
function updateCategory(selectedCategoryId: string) {
  if (isLoadingResults.value) return
  categoryId.value = selectedCategoryId
  ajaxSubmission(1)
}

function updatePage(requestedPage: number) {
  if (isLoadingResults.value) return
  ajaxSubmission(requestedPage)
}

function updateProperties(data: SearchSiteResultsData) {
  currentPage.value = data.currentPage
  pageItemsStart.value = data.pageItemsStart
  pageItemsEnd.value = data.pageItemsEnd
  results.value = data.results
  searchTerm.value = data.searchTerm
  totalItems.value = data.totalItems
}

function updateQueryString(newSearchTerm: string) {
  const searchParams = new URLSearchParams()
  searchParams.set(UrlParams.SearchTerm, newSearchTerm)
  window.history.replaceState({}, '', `${window.location.pathname}?${searchParams.toString()}`)
}

function updateSearchTerm(newSearchTerm: string) {
  if (isLoadingResults.value) return
  searchTerm.value = newSearchTerm
  updateQueryString(newSearchTerm)
  resetCategory()
  ajaxSubmission(1)
}

function handleQueryString() {
  const paramsFromUrl = new URLSearchParams(window.location.search)
  if (paramsFromUrl.has(UrlParams.SearchTerm)) searchTerm.value = paramsFromUrl.get(UrlParams.SearchTerm) ?? ''
}
handleQueryString()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-search-site {
  @apply tw-shared-base-flex-col-gap-6;
}

.ct-search-site__spinner {
  @apply
  invisible
  mx-auto
  my-13.75
  size-10 text-black;
}

.ct-search-site__spinner--visible {
  @apply visible;
}
</style>
