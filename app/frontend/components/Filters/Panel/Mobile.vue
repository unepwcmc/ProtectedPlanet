<template>
  <div class="ct-filters-panel-mobile">
    <div class="ct-filters-panel-mobile__topbar">
      <span
        class="ct-filters-panel-mobile__title"
        v-text="title"
      />
    </div>
    <div class="ct-filters-panel-mobile__groups">
      <h3
        class="ct-filters-panel-mobile__group-title"
        v-text="filtersTitle"
      />
      <ul class="ct-filters-panel-mobile__list">
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
    <span
      class="ct-filters-panel-mobile__footer"
      role="button"
      tabindex="0"
      @click="onToggleFilterPane"
      @keydown.enter.prevent="onToggleFilterPane"
      @keydown.space.prevent="onToggleFilterPane"
      v-html="filterCloseText"
    />
  </div>
</template>

<script setup lang="ts">
import { toRef } from 'vue'
import FiltersGroup from '@/components/Filters/Group.vue'
import useFreezeBackground from '@/composables/useFreezeBackground'
import type { FilterGroupFilter, FilterGroupSelection } from '@/types/backend'

const props = defineProps<{
  filterCloseText: string
  filters: FilterGroupFilter[]
  filtersTitle?: string
  gaId?: string
  isActive: boolean
  preSelected?: Record<string, Array<string | number>>
  resetKey?: number
  textClear: string
  title: string
}>()

useFreezeBackground(toRef(props, 'isActive'))

const emit = defineEmits<{
  'toggle:filterPane': []
  'update:filter': [payload: { id: string, options: FilterGroupSelection }]
}>()

// The CMS listing keeps its selection in one map on the page and passes it in;
// the search-areas serializer bakes it into each filter instead.
function preSelectedFor(filter: FilterGroupFilter) {
  return props.preSelected?.[filter.id] ?? filter.preSelected
}

function onUpdateFilter(payload: { id: string, options: FilterGroupSelection }) {
  emit('update:filter', payload)
}

function onToggleFilterPane() {
  emit('toggle:filterPane')
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-filters-panel-mobile {
  @apply
  fixed
  top-0
  left-0
  z-10
  w-full
  h-full
  bg-theme-grey-xlight
  tw-shared-base-flex-col-gap-6;
}

.ct-filters-panel-mobile__topbar {
  @apply
  flex
  items-center
  justify-center
  w-full
  bg-white
  border-b
  border-theme-grey-light
  h-13.5;
}

.ct-filters-panel-mobile__title {
  @apply tw-shared-font-hind-siliguri__light-lg-md-xl-grey-black;
}

.ct-filters-panel-mobile__groups {
  @apply
  h-[85%]
  w-full
  overflow-y-auto
  pr-5.5
  pb-6
  pl-5.5
  tw-shared-base-flex-col-gap-6;
}

.ct-filters-panel-mobile__group-title {
  @apply tw-shared-font-hind-siliguri__semibold-lg-md-xl-grey-black;
}

.ct-filters-panel-mobile__list {
  @apply
  tw-shared-base-flex-col-gap-9
  m-0
  p-0;
}

.ct-filters-panel-mobile__footer {
  @apply
  flex
  items-center
  justify-center
  fixed
  bottom-0
  w-full
  h-15.75
  bg-theme-grey-xdark
  tw-shared-font-hind-siliguri__normal-xl-white
  cursor-pointer;
}
</style>
