<template>
  <div class="ct-pame-table">
    <PameFilters
      :filters
      :isFetching
      :selectedFilterOptions
      :totalItems
      @apply="onApplyFilter"
      @update:isFetching="isFetching = $event"
    />
    <div
      class="ct-pame-table__body"
      :aria-busy="isFetching"
    >
      <table class="ct-pame-table__table">
        <PameTableHead :filters="attributes" />
        <tbody
          class="ct-pame-table__tbody
        ct-pame-table__tbody--list"
        >
          <PameTableRowMobile
            v-for="(item, index) in items"
            :key="item.id"
            :item
            :attributes
            :isLast="index === items.length - 1"
            @openModal="onOpenModal"
          />
        </tbody>
        <tbody
          class="ct-pame-table__tbody
        ct-pame-table__tbody--row"
        >
          <PameTableRowDesktop
            v-for="item in items"
            :key="item.id"
            :item
            @openModal="onOpenModal"
          />
        </tbody>
      </table>
      <div
        v-if="isFetching"
        class="ct-pame-table__overlay"
        role="status"
      >
        <span class="ct-pame-table__spinner" />
        <span class="ct-pame-table__overlay-text">Loading…</span>
      </div>
    </div>
    <PameTablePagination
      :currentPage
      :isFetching
      :itemsPerPage
      :totalItems
      :totalPages
      @requestItems="fetchItems"
    />
    <PameModal
      :text="modalText"
      :modalContent
      :isModalOpen
      @close="onCloseModal"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import PameFilters from '@/components/Pame/Filters/Index.vue'
import PameModal from '@/components/Pame/Modal.vue'
import PameTableHead from '@/components/Pame/Table/Head/Index.vue'
import PameTablePagination from '@/components/Pame/Table/Pagination.vue'
import PameTableRowDesktop from '@/components/Pame/Table/Row/Desktop.vue'
import PameTableRowMobile from '@/components/Pame/Table/Row/Mobile.vue'
import { postJson } from '@/lib/http'
import type { PameEvaluationItem, PameFilterSelection, PameTablePage, PameTableProps } from '@/types/backend'

type PameTable = PameTableProps
const props = defineProps<PameTable>()

// The one shared in-flight flag every PAME control (table, pagination, filters,
// CSV download) disables itself against — owned here since this is the common
// ancestor of all of them, and passed down as a prop (DownloadCsv writes back to
// it via `update:isFetching`, bubbled up through PameFilters).
const isFetching = ref(false)

const currentPage = ref(props.json.current_page)
const itemsPerPage = ref(props.json.per_page)
const totalItems = ref(props.json.total_entries)
const totalPages = ref(props.json.total_pages)
const items = ref(props.json.items)

// PameModal is a direct sibling here, same as the rows that open it — owning
// this locally instead of in the store keeps that connection explicit.
const modalContent = ref<PameEvaluationItem | null>(null)
const isModalOpen = ref(false)

function onOpenModal(item: PameEvaluationItem) {
  modalContent.value = item
  isModalOpen.value = true
}

function onCloseModal() {
  isModalOpen.value = false
}

// The URL is the only place applied filters are stored — no Pinia state for
// them. Read on load so a bookmarked/shared/back-navigated link reproduces the
// same filtered table, and written back out on every apply (see updateQueryString).
const FILTER_PARAM_PREFIX = 'pame_filters'
const requestedPage = ref(1)
const selectedFilterOptions = ref<PameFilterSelection[]>(readFiltersFromUrl())

function defaultFilterOptions(): PameFilterSelection[] {
  // PameEvaluation.generate_query only reads filters that are present in this
  // array, so every real filter needs a (possibly empty) entry.
  return props.filters
    .filter(filter => filter.options.length > 0)
    .map(filter => ({ name: filter.name, options: [], type: filter.type }))
}

function readFiltersFromUrl(): PameFilterSelection[] {
  const params = new URLSearchParams(window.location.search)

  return defaultFilterOptions().map((filter) => {
    const key = `${FILTER_PARAM_PREFIX}[${filter.name}][]`
    return params.has(key) ? { ...filter, options: params.getAll(key) } : filter
  })
}

function updateQueryString(filters: PameFilterSelection[]) {
  const params = new URLSearchParams()

  filters.forEach((filter) => {
    filter.options.forEach((option) => {
      params.append(`${FILTER_PARAM_PREFIX}[${filter.name}][]`, String(option))
    })
  })

  const query = params.toString()
  window.history.replaceState({}, '', `${window.location.pathname}${query ? `?${query}` : ''}`)
}

function updatePage(data: PameTablePage) {
  currentPage.value = data.current_page
  itemsPerPage.value = data.per_page
  totalItems.value = data.total_entries
  totalPages.value = data.total_pages
  items.value = data.items
}

// Guarded against overlapping requests (not just disabled buttons) since a filter
// apply and a pagination click can race each other, not only repeat clicks on the
// same control.
function fetchItems(page = requestedPage.value) {
  if (isFetching.value) return

  requestedPage.value = page
  isFetching.value = true

  postJson<PameTablePage>(props.endpoint, {
    requested_page: page,
    filters: selectedFilterOptions.value
  }).then(updatePage).finally(() => {
    isFetching.value = false
  })
}

function onApplyFilter(name: string, options: string[]) {
  selectedFilterOptions.value = selectedFilterOptions.value.map(filter => (
    filter.name === name ? { ...filter, options } : filter
  ))
  updateQueryString(selectedFilterOptions.value)
  fetchItems(1)
}

// The initial `json` prop is always the unfiltered SSR default (Data::GdpameController#index
// ignores query params), so re-fetch immediately when the page loads with filters
// already in the URL — otherwise a bookmarked/shared filtered link shows unfiltered results.
if (selectedFilterOptions.value.some(filter => filter.options.length > 0)) fetchItems(1)
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-pame-table {
  @apply
  tw-shared-base-flex-col-gap-3-md-gap-6
  min-h-125;
}

.ct-pame-table__table {
  @apply w-full;
}

.ct-pame-table__tbody--list {
  @apply
  table-row-group
  xl:hidden;
}

.ct-pame-table__tbody--row {
  @apply
  hidden
  xl:table-row-group;
}

.ct-pame-table__body {
  @apply relative;
}

.ct-pame-table__overlay {
  @apply
  absolute
  inset-0
  z-10
  tw-shared-base-flex-col-gap-2
  items-center
  justify-center
  bg-white/70;
}

.ct-pame-table__spinner {
  @apply
  tw-shared-icon-loading-spinner
  m-0;
}

.ct-pame-table__overlay-text {
  @apply tw-shared-font-hind-siliguri__semibold-xl-grey-black;
}
</style>
