<template>
  <div class="search__results">
    <div
      v-if="hasResults"
      class="search__results-content"
    >
      <div class="search__results-bar">
        <h2 v-text="`${results.title} (${totalAsString})`" />
      </div>
      <div class="cards--search-results-areas">
        <SearchAreasResultsItem
          v-for="(area, index) in results.areas"
          :key="index"
          :countryFlag="area.countryFlag"
          :geoType="results.geoType"
          :image="area.image"
          :totalAreas="area.totalAreas"
          :title="area.title"
          :url="area.url"
        />
      </div>
      <FiltersPaginationInfinityScroll
        :triggerClass="smTriggerElement"
        :total="results.total"
        :totalPages="results.totalPages"
        :resetKey
        @requestMore="requestMore"
      />
    </div>
    <p
      v-else
      class="search__results-none"
      v-html="noResultsText"
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import SearchAreasResultsItem from '@/components/SearchAreas/Results/Item.vue'
import FiltersPaginationInfinityScroll from '@/components/Filters/PaginationInfinityScroll.vue'
import type { SearchAreasResults } from '@/types/backend'

const props = defineProps<{
  noResultsText: string
  results: SearchAreasResults
  smTriggerElement: string
  resetKey?: number
}>()

const emit = defineEmits<{ requestMore: [page: number] }>()

const hasResults = computed(() => props.results.total > 0)
const totalAsString = computed(() => Number.parseFloat(String(props.results.total)).toLocaleString())

function requestMore(page: number) {
  emit('requestMore', page)
}
</script>
