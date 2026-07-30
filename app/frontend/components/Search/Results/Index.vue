<template>
  <div class="search--results">
    <p
      v-show="hasResults"
      class="search__total"
      v-text="text"
    />
    <div class="cards--search-results">
      <SearchSiteResultsItem
        v-for="(result, index) in results"
        :key="index"
        v-bind="result"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import SearchSiteResultsItem from '@/components/Search/Results/Item.vue'
import type { SearchSiteResult } from '@/types/backend'

const props = defineProps<{
  results: SearchSiteResult[]
  resultsText: string
  totalItems: number
}>()

const hasResults = computed(() => props.totalItems > 0)
const text = computed(() => `(${props.totalItems} ${props.resultsText})`)
</script>
