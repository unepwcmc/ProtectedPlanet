<template>
  <div class="filtered-table pame">
    <PameFilters
      :filters
      :totalItems
      @requestItems="fetchItems"
    />
    <div
      class="ct-pame-table__body"
      :aria-busy="pameStore.isFetching"
    >
      <table class="table table--pame">
        <PameTableHead :filters="attributes" />
        <tbody class="table__tbody table__tbody--list">
          <PameTableRowMobile
            v-for="(item, index) in items"
            :key="item.id"
            :item
            :attributes
            :isLast="index === items.length - 1"
          />
        </tbody>
        <tbody class="table__tbody table__tbody--row">
          <PameTableRow
            v-for="item in items"
            :key="item.id"
            :item
          />
        </tbody>
      </table>

      <div
        v-if="pameStore.isFetching"
        class="ct-pame-table__overlay"
        role="status"
      >
        <span class="icon--loading-spinner ct-pame-table__spinner" />
        <span class="ct-pame-table__overlay-text">Loading…</span>
      </div>
    </div>
    <PameTablePagination
      :currentPage
      :itemsPerPage
      :totalItems
      :totalPages
      @requestItems="fetchItems"
    />
    <PameModal :text="modalText" />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import PameFilters from '@/components/Pame/Filters/Index.vue'
import PameModal from '@/components/Pame/Modal.vue'
import PameTableHead from '@/components/Pame/Table/Head/Index.vue'
import PameTablePagination from '@/components/Pame/Table/Pagination.vue'
import PameTableRow from '@/components/Pame/Table/Row/Index.vue'
import PameTableRowMobile from '@/components/Pame/Table/Row/Mobile.vue'
import { postJson } from '@/lib/http'
import { usePameStore } from '@/stores/usePameStore'
import type { PameTablePage, PameTableProps } from '@/types/backend'

type PameTable = PameTableProps
const props = defineProps<PameTable>()

const pameStore = usePameStore()

const currentPage = ref(props.json.current_page)
const itemsPerPage = ref(props.json.per_page)
const totalItems = ref(props.json.total_entries)
const totalPages = ref(props.json.total_pages)
const items = ref(props.json.items)

function updatePage(data: PameTablePage) {
  currentPage.value = data.current_page
  itemsPerPage.value = data.per_page
  totalItems.value = data.total_entries
  totalPages.value = data.total_pages
  items.value = data.items
}

// Guarded against overlapping requests (not just disabled buttons) since a filter
// apply and a pagination click can race each other, not only repeat clicks on the
// same control. `pameStore.isFetching` is the one shared in-flight flag every PAME
// control (pagination, filters, CSV download) disables itself against.
function fetchItems() {
  if (pameStore.isFetching) return

  pameStore.setFetching(true)

  postJson<PameTablePage>(props.endpoint, {
    requested_page: pameStore.requestedPage,
    filters: pameStore.selectedFilterOptions
  }).then(updatePage).finally(() => {
    pameStore.setFetching(false)
  })
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

/* Only the table body gets an overlay/busy treatment — filters and pagination
   disable themselves independently (see PameFiltersFilter/PameTablePagination),
   they don't need to be visually dimmed. */
.ct-pame-table__body {
  @apply relative;
}

.ct-pame-table__overlay {
  @apply absolute inset-0 z-10 flex flex-col items-center justify-center gap-2 bg-white/70;
}

.ct-pame-table__spinner {
  @apply m-0;
}

.ct-pame-table__overlay-text {
  @apply text-sm font-bold text-theme-grey-black;
}
</style>
