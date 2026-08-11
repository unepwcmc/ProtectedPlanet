<template>
  <div class="ct-listing-filters-panel-desktop">
    <h3
      class="ct-listing-filters-panel-desktop__title"
      v-text="filtersTitle"
    />
    <ul class="ct-listing-filters-panel-desktop__list">
      <li
        v-for="filter in filters"
        :key="filter.id"
      >
        <ListingFilterGroup
          :filter
          :gaId
          :preSelected="preSelected?.[filter.id]"
          :textClear
          @update:filter="onUpdateFilter"
        />
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import ListingFilterGroup from '@/components/Listing/FilterGroup.vue'
import type { ListingFilter } from '@/types/backend'

defineProps<{
  filters: ListingFilter[]
  filtersTitle?: string
  gaId?: string
  preSelected?: Record<string, Array<string | number>>
  textClear: string
}>()

const emit = defineEmits<{ 'update:filterGroup': [payload: { id: string, options: Array<string | number> }] }>()

function onUpdateFilter(payload: { id: string, options: Array<string | number> }) {
  emit('update:filterGroup', payload)
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-listing-filters-panel-desktop {
  @apply
  grow
  pt-6
  pr-6
  shrink-0
  tw-shared-base-flex-col-gap-6
  overflow-y-auto;
}

.ct-listing-filters-panel-desktop__title {
  @apply tw-shared-font-hind-siliguri__bold-base-md-xl-grey-black;
}

.ct-listing-filters-panel-desktop__list {
  @apply
  tw-shared-base-flex-col-gap-6
  m-0
  p-0;
}
</style>
