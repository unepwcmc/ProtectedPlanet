<template>
  <div class="listing__results">
    <div v-show="hasResults">
      <div
        v-if="template === 'news'"
        class="listing__cards-news"
      >
        <ListingPageCardNewsCard
          v-for="(result, index) in results.results"
          :key="index"
          v-bind="result"
          :url="result.url ?? ''"
        />
      </div>
      <div
        v-else
        class="listing__cards-resources"
      >
        <ListingPageCardResourcesCard
          v-for="(result, index) in results.results"
          :key="index"
          v-bind="result"
        />
      </div>
      <ListingPaginationInfinityScroll
        :resetKey="resetKey"
        :total="results.total"
        :totalPages="results.totalPages"
        @requestMore="emit('requestMore', $event)"
      />
    </div>
    <p
      v-show="!hasResults"
      class="search__results-none"
      v-html="textNoResults"
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import ListingPageCardNewsCard from '@/components/ListingPageCard/News/Card.vue'
import ListingPageCardResourcesCard from '@/components/ListingPageCard/Resources/Card.vue'
import ListingPaginationInfinityScroll from '@/components/Listing/PaginationInfinityScroll.vue'
import type { ListingResults } from '@/types/backend'

const props = defineProps<{
  resetKey: number
  results: ListingResults
  template: 'news' | 'resources'
  textNoResults: string
}>()

const emit = defineEmits<{ requestMore: [page: number] }>()

const hasResults = computed(() => props.results.total > 0)
</script>
