<template>
  <div
    v-show="isActive"
    class="filters--sidebar filter__pane"
  >
    <div class="filter__pane-topbar">
      <span
        class="filter__pane-title"
        v-text="title"
      />
    </div>
    <ul class="filter__filter-groups">
      <li
        v-for="(group, index) in filterGroups"
        :key="index"
        class="filter__group"
      >
        <h3 v-text="group.title" />
        <ListingFilterGroup
          v-for="filter in group.filters"
          :key="filter.id"
          :filter="filter"
          :gaId="gaId"
          :preSelected="preSelected?.[filter.id]"
          :textClear="textClear"
          @update:filter="onUpdateFilter"
        />
      </li>
    </ul>
    <span
      class="filter__pane-view"
      @click="$emit('toggle:filterPane')"
      v-html="filterCloseText"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import ListingFilterGroup from '@/components/Listing/FilterGroup.vue'
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
  'update:filterGroup': [options: Record<string, Array<string | number>>]
}>()

const activeFilterOptions = ref<Record<string, Array<string | number>>>({})

function onUpdateFilter(payload: { id: string, options: Array<string | number> }) {
  activeFilterOptions.value[payload.id] = payload.options
  emit('update:filterGroup', activeFilterOptions.value)
}
</script>
