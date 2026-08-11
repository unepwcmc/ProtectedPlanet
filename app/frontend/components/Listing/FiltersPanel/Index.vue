<template>
  <div
    v-show="isActive"
    class="ct-listing-filters-panel"
  >
    <ListingFiltersPanelDesktop
      class="ct-listing-filters-panel--desktop"
      :filterGroups
      :gaId
      :preSelected
      :textClear
      @update:filterGroup="onUpdateFilterGroup"
    />
    <ListingFiltersPanelMobile
      class="ct-listing-filters-panel--mobile"
      :filterCloseText
      :filterGroups
      :gaId
      :isActive
      :preSelected
      :textClear
      :title
      @toggle:filterPane="onToggleFilterPane"
      @update:filterGroup="onUpdateFilterGroup"
    />
  </div>
</template>

<script setup lang="ts">
import ListingFiltersPanelDesktop from '@/components/Listing/FiltersPanel/Desktop.vue'
import ListingFiltersPanelMobile from '@/components/Listing/FiltersPanel/Mobile.vue'
import type { ListingFilterGroup as ListingFilterGroupType } from '@/types/backend'

defineProps<{
  filterCloseText: string
  filterGroups: ListingFilterGroupType[]
  gaId?: string
  isActive: boolean
  preSelected?: Record<string, Array<string | number>>
  textClear: string
  title: string
}>()

const emit = defineEmits<{
  'toggle:filterPane': []
  'update:filterGroup': [payload: { id: string, options: Array<string | number> }]
}>()

function onToggleFilterPane() {
  emit('toggle:filterPane')
}

function onUpdateFilterGroup(payload: { id: string, options: Array<string | number> }) {
  emit('update:filterGroup', payload)
}
</script>
<style scoped lang="css">
@reference "#importtailwindcss";

.ct-listing-filters-panel--mobile {
  @apply
  flex
  lg:hidden;
}

.ct-listing-filters-panel--desktop {
  @apply
  hidden
  lg:flex;
}
</style>
