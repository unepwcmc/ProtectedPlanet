<template>
  <div
    v-if="isRendered"
    v-show="isActive"
    class="ct-filters-panel"
  >
    <FiltersPanelMobile
      v-if="isSmall||isMedium"
      class="ct-filters-panel__mobile"
      :filterCloseText
      :filters
      :filtersTitle
      :gaId
      :isActive
      :preSelected
      :resetKey
      :textClear
      :title
      @toggle:filterPane="onToggleFilterPane"
      @update:filter="onUpdateFilter"
    />
    <FiltersPanelDesktop
      v-else
      class="ct-filters-panel__desktop"
      :filters
      :filtersTitle
      :gaId
      :modifier
      :preSelected
      :resetKey
      :textClear
      @update:filter="onUpdateFilter"
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import FiltersPanelDesktop from '@/components/Filters/Panel/Desktop.vue'
import FiltersPanelMobile from '@/components/Filters/Panel/Mobile.vue'
import useBreakpoint from '@/composables/useBreakpoint'
import type { FilterGroupFilter, FilterGroupSelection } from '@/types/backend'

const props = defineProps<{
  filterCloseText: string
  filters: FilterGroupFilter[]
  filtersTitle?: string
  gaId?: string
  isActive: boolean
  keepMounted?: boolean
  modifier?: string
  preSelected?: Record<string, Array<string | number>>
  resetKey?: number
  textClear: string
  title: string
}>()

const emit = defineEmits<{
  'toggle:filterPane': []
  'update:filterGroup': [payload: { id: string, options: FilterGroupSelection }]
}>()

const { isSmall, isMedium } = useBreakpoint()

// The CMS listing hides the panel rather than tearing it down, so groups that
// were preselected from the query string still prime the page on first load.
const isRendered = computed(() => props.keepMounted || props.isActive)

function onToggleFilterPane() {
  emit('toggle:filterPane')
}

function onUpdateFilter(payload: { id: string, options: FilterGroupSelection }) {
  emit('update:filterGroup', payload)
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-filters-panel__mobile {
  @apply
  flex
  lg:hidden;
}

.ct-filters-panel__desktop {
  @apply
  hidden
  lg:flex;
}
</style>
