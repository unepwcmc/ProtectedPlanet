<template>
  <div class="ct-search-areas-filters-panel-desktop">
    <h3
      class="ct-search-areas-filters-panel-desktop__title"
      v-text="filtersTitle"
    />
    <ul class="ct-search-areas-filters-panel-desktop__list">
      <SearchAreasFilterGroup
        v-for="filter in filters"
        :id="filter.id"
        :key="filter.id"
        class="ct-search-areas-filters-panel-desktop__item"
        :gaId
        :name="filter.name"
        :options="filter.options"
        :preSelected="filter.preSelected"
        :resetKey
        :textClear
        :title="filter.title"
        :type="filter.type"
        @update:filter="onUpdateFilter"
      />
    </ul>
  </div>
</template>

<script setup lang="ts">
import SearchAreasFilterGroup from '@/components/SearchAreas/FilterGroup.vue'
import type { SearchFilter } from '@/types/backend'

defineProps<{
  filters: SearchFilter[]
  filtersTitle: string
  gaId: string
  resetKey?: number
  textClear: string
}>()

const emit = defineEmits<{ 'update:filter': [payload: { id: string, options: unknown }] }>()

function onUpdateFilter(payload: { id: string, options: unknown }) {
  emit('update:filter', payload)
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-search-areas-filters-panel-desktop {
  @apply
  w-full
  tw-shared-base-flex-col-gap-6
  py-6
  pr-9;
}

.ct-search-areas-filters-panel-desktop__title {
  @apply tw-shared-font-hind-siliguri__semibold-base-md-xl-grey-black;
}

.ct-search-areas-filters-panel-desktop__list {
  @apply
  tw-shared-base-flex-col-gap-6
  grow
  min-h-0
  m-0
  p-0;
}
</style>
