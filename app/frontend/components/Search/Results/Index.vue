<template>
  <div class="ct-search-results">
    <p
      v-show="hasResults"
      class="ct-search-results__total"
      v-text="text"
    />
    <div class="ct-search-results__list">
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

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-search-results {
  @apply tw-shared-base-flex-col-gap-6;
}

.ct-search-results__total {
  @apply
  px-3
  tw-shared-font-hind-siliguri__semibold-lg-md-xl-grey;
}

.ct-search-results__list {
  @apply
  flex
  flex-col
  gap-y-5;
}
</style>
