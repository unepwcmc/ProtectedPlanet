<template>
  <div class="ct-pame-filters">
    <ul class="ct-pame-filters__list">
      <PameFiltersFilter
        v-for="filter in filters"
        :key="filter.name"
        :name="filter.name"
        :title="filter.title"
        :options="filter.options"
        :appliedOptions="appliedOptionsByName[filter.name] ?? []"
        :isFetching
        :isOpen="openFilterName === filter.name"
        @toggle="onToggleFilter(filter.name)"
        @apply="onApplyFilter(filter.name, $event)"
      />
    </ul>
    <PameTableDownloadCsv
      :isFetching
      :selectedFilterOptions
      :totalItems
      @update:isFetching="emit('update:isFetching', $event)"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import PameTableDownloadCsv from '@/components/Pame/Table/DownloadCsv.vue'
import PameFiltersFilter from '@/components/Pame/Filters/Filter/Index.vue'
import type { PameFilter, PameFilterSelection } from '@/types/backend'

const props = defineProps<{
  filters: PameFilter[]
  isFetching: boolean
  selectedFilterOptions: PameFilterSelection[]
  totalItems: number
}>()

const emit = defineEmits<{
  'apply': [name: string, options: string[]]
  'update:isFetching': [value: boolean]
}>()

const openFilterName = ref<string | null>(null)

// The parent (Pame/Table/Index.vue) owns the applied filters — sourced from,
// and written back to, the URL — this just looks each filter's current value
// up by name so a reopened dropdown always starts from what's really applied.
const appliedOptionsByName = computed(() => (
  Object.fromEntries(props.selectedFilterOptions.map(filter => [filter.name, filter.options as string[]]))
))

function onToggleFilter(name: string) {
  openFilterName.value = openFilterName.value === name ? null : name
}

function onApplyFilter(name: string, options: string[]) {
  emit('apply', name, options)
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-pame-filters {
  @apply
  tw-shared-base-flex-gap-3
  flex-wrap
  justify-between;
}

.ct-pame-filters__list {
  @apply tw-shared-base-flex-wrap-gap-4-lg-gap-2;
}
</style>
