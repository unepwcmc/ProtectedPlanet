<template>
  <div
    class="ct-filters-panel-desktop"
    :class="modifier && `ct-filters-panel-desktop--${modifier}`"
  >
    <h3
      class="ct-filters-panel-desktop__title"
      v-text="filtersTitle"
    />
    <ul class="ct-filters-panel-desktop__list">
      <FiltersGroup
        v-for="filter in filters"
        :id="filter.id"
        :key="filter.id"
        :gaId
        :name="filter.name"
        :options="filter.options"
        :preSelected="preSelectedFor(filter)"
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
import FiltersGroup from '@/components/Filters/Group.vue'
import type { FilterGroupFilter, FilterGroupSelection } from '@/types/backend'

const props = defineProps<{
  filters: FilterGroupFilter[]
  filtersTitle?: string
  gaId?: string
  modifier?: string
  preSelected?: Record<string, Array<string | number>>
  resetKey?: number
  textClear: string
}>()

const emit = defineEmits<{ 'update:filter': [payload: { id: string, options: FilterGroupSelection }] }>()

// The CMS listing keeps its selection in one map on the page and passes it in;
// the search-areas serializer bakes it into each filter instead.
function preSelectedFor(filter: FilterGroupFilter) {
  return props.preSelected?.[filter.id] ?? filter.preSelected
}

function onUpdateFilter(payload: { id: string, options: FilterGroupSelection }) {
  emit('update:filter', payload)
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-filters-panel-desktop {
  @apply tw-shared-base-flex-col-gap-6;
}

.ct-filters-panel-desktop--listing {
  @apply
  grow
  shrink-0
  pt-6
  pr-6
  overflow-y-auto;
}

.ct-filters-panel-desktop--search-areas {
  @apply
  w-full
  py-6
  pr-9
  lg:border-r
  lg:border-solid
  lg:border-theme-grey;
}

.ct-filters-panel-desktop__title {
  @apply tw-shared-font-hind-siliguri__semibold-base-md-xl-grey-black;
}

.ct-filters-panel-desktop__list {
  @apply
  tw-shared-base-flex-col-gap-6
  m-0
  p-0;
}

.ct-filters-panel-desktop--search-areas .ct-filters-panel-desktop__list {
  @apply
  grow
  min-h-0;
}
</style>
