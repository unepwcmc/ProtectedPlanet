<template>
  <div
    v-if="isActive"
    class="ct-search-areas-filters-panel"
  >
    <SearchAreasFiltersPanelMobile
      v-if="isSmall||isMedium"
      class="ct-search-areas-filters-panel--mobile"
      :filterCloseText
      :filters
      :filtersTitle
      :gaId
      :isActive
      :resetKey
      :textClear
      :title
      @toggle:filterPane="onToggleFilterPane"
      @update:filter="onUpdateFilter"
    />
    <SearchAreasFiltersPanelDesktop
      v-else
      class="ct-search-areas-filters-panel--desktop"
      :filters
      :filtersTitle
      :gaId
      :resetKey
      :textClear
      @update:filter="onUpdateFilter"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import SearchAreasFiltersPanelDesktop from '@/components/SearchAreas/FiltersPanel/Desktop.vue'
import SearchAreasFiltersPanelMobile from '@/components/SearchAreas/FiltersPanel/Mobile.vue'
import type { SearchFilter } from '@/types/backend'
import useBreakpoint from '@/composables/useBreakpoint'

defineProps<{
  filterCloseText: string
  filters: SearchFilter[]
  filtersTitle: string
  gaId: string
  isActive: boolean
  resetKey?: number
  textClear: string
  title: string
}>()

const emit = defineEmits<{
  'toggle:filterPane': []
  'update:filterGroup': [activeFilterOptions: Record<string, unknown>]
}>()

const { isSmall, isMedium } = useBreakpoint()

const activeFilterOptions = ref<Record<string, unknown>>({})

function onToggleFilterPane() {
  emit('toggle:filterPane')
}

function onUpdateFilter(updatedFilter: { id: string, options: unknown }) {
  activeFilterOptions.value[updatedFilter.id] = updatedFilter.options
  emit('update:filterGroup', activeFilterOptions.value)
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-search-areas-filters-panel--mobile {
  @apply flex lg:hidden;
}

.ct-search-areas-filters-panel--desktop {
  @apply
  hidden
  lg:flex
  lg:border-r
  lg:border-solid
  lg:border-theme-grey;
}
</style>
