<template>
  <ul class="ct-listing-filters-panel-desktop__groups">
    <li
      v-for="(group, index) in filterGroups"
      :key="index"
      class="ct-listing-filters-panel-desktop__group"
    >
      <h3
        class="ct-listing-filters-panel-desktop__group-title"
        v-text="group.title"
      />
      <ListingFilterGroup
        v-for="filter in group.filters"
        :key="filter.id"
        :filter
        :gaId
        :preSelected="preSelected?.[filter.id]"
        :textClear
        @update:filter="onUpdateFilter"
      />
    </li>
  </ul>
</template>

<script setup lang="ts">
import ListingFilterGroup from '@/components/Listing/FilterGroup.vue'
import type { ListingFilterGroup as ListingFilterGroupType } from '@/types/backend'

defineProps<{
  filterGroups: ListingFilterGroupType[]
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

.ct-listing-filters-panel-desktop__groups {
  @apply
  grow
  pt-6
  pr-6
  shrink-0
  tw-shared-base-flex-col-gap-6
  overflow-y-auto;
}

.ct-listing-filters-panel-desktop__group {
  @apply tw-shared-base-flex-col-gap-6;
}

.ct-listing-filters-panel-desktop__group-title {
  @apply tw-shared-font-hind-siliguri__bold-base-md-xl-grey-black;
}
</style>
