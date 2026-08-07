<template>
  <div
    v-show="isActive"
    class="filters--sidebar"
  >
    <div class="filter__pane">
      <div class="filter__pane-topbar">
        <span
          class="filter__pane-title"
          v-text="title"
        />
      </div>
      <div class="filter__filter-groups">
        <div
          v-for="filterGroup in filterGroups"
          :key="filterGroup.title"
          class="filter__group"
        >
          <h3 v-text="filterGroup.title" />
          <SearchAreasFilterGroup
            v-for="filter in filterGroup.filters"
            :id="filter.id"
            :key="filter.id"
            :gaId
            :name="filter.name"
            :options="filter.options"
            :preSelected="filter.preSelected"
            :title="filter.title"
            :textClear
            :type="filter.type"
            :resetKey
            @update:filter="updateFilterGroup"
          />
        </div>
      </div>
      <span
        class="filter__pane-view"
        @click="toggleFilterPane"
        v-text="filterCloseText"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import SearchAreasFilterGroup from '@/components/SearchAreas/FilterGroup.vue'
import type { SearchFilterGroup } from '@/types/backend'

defineProps<{
  filterCloseText: string
  filterGroups: SearchFilterGroup[]
  gaId: string
  isActive: boolean
  textClear: string
  title: string
  // Bumped by SearchAreas/Page.vue whenever a new search term is submitted —
  // replaces the legacy $eventHub 'reset:filter-options' broadcast.
  resetKey?: number
}>()

const emit = defineEmits<{
  'update:filterGroup': [activeFilterOptions: Record<string, unknown>]
  'toggle:filterPane': []
}>()

const activeFilterOptions = ref<Record<string, unknown>>({})

function toggleFilterPane() {
  emit('toggle:filterPane')
}

function updateFilterGroup(updatedFilter: { id: string, options: unknown }) {
  activeFilterOptions.value[updatedFilter.id] = updatedFilter.options
  emit('update:filterGroup', activeFilterOptions.value)
}
</script>
