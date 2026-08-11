<template>
  <div class="ct-listing-filters-panel-mobile">
    <div class="ct-listing-filters-panel-mobile__topbar">
      <span
        class="ct-listing-filters-panel-mobile__title"
        v-text="title"
      />
    </div>
    <div class="ct-listing-filters-panel-mobile__groups">
      <h3
        class="ct-listing-filters-panel-mobile__group-title"
        v-text="filtersTitle"
      />
      <ul class="ct-listing-filters-panel-mobile__list">
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
    <span
      class="ct-listing-filters-panel-mobile__footer"
      @click="onToggleFilterPane"
      v-html="filterCloseText"
    />
  </div>
</template>

<script setup lang="ts">
import { toRef } from 'vue'
import ListingFilterGroup from '@/components/Listing/FilterGroup.vue'
import useFreezeBackground from '@/composables/useFreezeBackground'
import type { ListingFilter } from '@/types/backend'

const props = defineProps<{
  filterCloseText: string
  filters: ListingFilter[]
  filtersTitle?: string
  gaId?: string
  isActive: boolean
  preSelected?: Record<string, Array<string | number>>
  textClear: string
  title: string
}>()

useFreezeBackground(toRef(props, 'isActive'))

const emit = defineEmits<{
  'toggle:filterPane': []
  'update:filterGroup': [payload: { id: string, options: Array<string | number> }]
}>()

function onUpdateFilter(payload: { id: string, options: Array<string | number> }) {
  emit('update:filterGroup', payload)
}

function onToggleFilterPane() {
  emit('toggle:filterPane')
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-listing-filters-panel-mobile {
  @apply
  fixed
  top-0
  left-0
  right-0
  w-full
  h-full
  bg-theme-grey-xlight
  tw-shared-base-flex-col-gap-6;
}

.ct-listing-filters-panel-mobile__topbar {
  @apply
  flex
  items-center
  border-b
  border-solid
  border-theme-grey
  p-6
  h-13.5;
}

.ct-listing-filters-panel-mobile__title {
  @apply tw-shared-font-hind-siliguri__light-lg-md-xl-grey-black;
}

.ct-listing-filters-panel-mobile__groups {
  @apply
  h-[85%]
  w-full
  overflow-y-auto
  pr-5.5
  pb-6
  pl-5.5
  tw-shared-base-flex-col-gap-6;
}

.ct-listing-filters-panel-mobile__group-title {
  @apply tw-shared-font-hind-siliguri__bold-lg-md-xl-grey-black;
}

.ct-listing-filters-panel-mobile__list {
  @apply
  tw-shared-base-flex-col-gap-9
  m-0
  p-0;
}

.ct-listing-filters-panel-mobile__footer {
  @apply
  flex
  items-center
  justify-center
  absolute
  bottom-0
  w-full
  h-15.75
  bg-theme-grey-xdark
  text-white
  text-xl
  font-bold;
}
</style>
