<template>
  <div class="search--main">
    <SearchSiteInput
      :disabled="loadingResults"
      :placeholder
      :prePopulatedSearchTerm="searchTerm"
      @submit:search="updateSearchTerm"
    />
    <SearchSiteTabStrip
      :children="categories"
      class="tabs--search-main"
      :defaultSelectedId="defaultCategoryId"
      :disabled="loadingResults"
      :gaId
      :preSelectedId="categoryId"
      @click:tab="updateCategory"
    />
    <SearchSiteResults
      v-show="!loadingResults"
      :results
      :resultsText
      :totalItems
    />
    <span
      class="icon--loading-spinner margin-center search__spinner"
      :class="{ 'icon-visible': loadingResults }"
    />
    <SearchSitePagination
      :currentPage
      :loading="loadingResults"
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
import SearchSiteInput from '@/components/Search/SiteInput.vue'
import SearchSitePagination from '@/components/Search/Pagination.vue'
import SearchSiteResults from '@/components/Search/Results/Index.vue'
import SearchSiteTabStrip from '@/components/SearchAreas/TabStrip/Index.vue'
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
const loadingResults = ref(false)
const pageItemsEnd = ref(props.dataPageLoad.pageItemsEnd)
const pageItemsStart = ref(props.dataPageLoad.pageItemsStart)
const results = ref(props.dataPageLoad.results)
const searchTerm = ref(props.dataPageLoad.searchTerm)
const totalItems = ref(props.dataPageLoad.totalItems)

function resetCategory() {
  categoryId.value = defaultCategoryId
}

async function ajaxSubmission(requestedPage: number) {
  loadingResults.value = true

  const response = await getJson<SearchSiteResultsData>(props.endpoint, {
    filters: JSON.stringify({ ancestor: categoryId.value }),
    items_per_page: String(props.itemsPerPage ?? 15),
    requested_page: String(requestedPage),
    search_term: searchTerm.value
  })

  updateProperties(response)
  loadingResults.value = false
}
function updateCategory(selectedCategoryId: string) {
  if (loadingResults.value) return
  categoryId.value = selectedCategoryId
  ajaxSubmission(1)
}

function updatePage(requestedPage: number) {
  if (loadingResults.value) return
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
  if (loadingResults.value) return
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
