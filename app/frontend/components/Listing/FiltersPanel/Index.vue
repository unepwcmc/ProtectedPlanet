<template>
  <div
    v-show="isActive"
    class="ct-listing-filters-panel"
  >
    <ListingFiltersPanelMobile
      v-if="isSmall||isMedium"
      class="ct-listing-filters-panel--mobile"
      :filterCloseText
      :filters
      :filtersTitle
      :gaId
      :isActive
      :preSelected
      :textClear
      :title
      @toggle:filterPane="onToggleFilterPane"
      @update:filterGroup="onUpdateFilterGroup"
    />
    <ListingFiltersPanelDesktop
      v-else
      class="ct-listing-filters-panel--desktop"
      :filters
      :filtersTitle
      :gaId
      :preSelected
      :textClear
      @update:filterGroup="onUpdateFilterGroup"
    />
  </div>
</template>

<script setup lang="ts">
import ListingFiltersPanelDesktop from '@/components/Listing/FiltersPanel/Desktop.vue'
import ListingFiltersPanelMobile from '@/components/Listing/FiltersPanel/Mobile.vue'
import type { ListingFilter } from '@/types/backend'
import useBreakpoint from '@/composables/useBreakpoint'

defineProps<{
  filterCloseText: string
  filters: ListingFilter[]
  filtersTitle?: string
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

const { isSmall, isMedium } = useBreakpoint()
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
