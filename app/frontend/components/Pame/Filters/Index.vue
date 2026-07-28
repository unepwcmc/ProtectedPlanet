<template>
  <div class="filters--pame">
    <ul class="filter__wrapper">
      <PameFiltersFilter
        v-for="filter in filters"
        :key="filter.name"
        :name="filter.name"
        :title="filter.title"
        :options="filter.options"
        :isOpen="openFilterName === filter.name"
        @toggle="onToggleFilter(filter.name)"
        @apply="onApplyFilter(filter.name, $event)"
      />
    </ul>
    <PameTableDownloadCsv
      class="filter__button-download"
      :totalItems
    />
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import PameTableDownloadCsv from '@/components/Pame/Table/DownloadCsv.vue'
import PameFiltersFilter from '@/components/Pame/Filters/Filter/Index.vue'
import { usePameStore } from '@/stores/usePameStore'
import type { PameFilter } from '@/types/backend'

const props = defineProps<{
  filters: PameFilter[]
  totalItems: number
}>()

const emit = defineEmits<{ requestItems: [] }>()

const pameStore = usePameStore()
const openFilterName = ref<string | null>(null)

function onToggleFilter(name: string) {
  openFilterName.value = openFilterName.value === name ? null : name
}

function onApplyFilter(name: string, options: string[]) {
  pameStore.updateFilterOptions(name, options)
  pameStore.updateRequestedPage(1)
  emit('requestItems')
}

// Primes the store with one empty-options entry per real filter, same as the
// legacy Filters.vue's `createSelectedFilterOptions` — PameEvaluation.generate_query
// only reads filters that are present in this array.
onMounted(() => {
  pameStore.setFilterOptions(
    props.filters
      .filter(filter => filter.options.length > 0)
      .map(filter => ({ name: filter.name, options: [], type: filter.type }))
  )
})
</script>
