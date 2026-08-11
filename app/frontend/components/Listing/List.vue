<template>
  <div class="ct-listing-list">
    <template v-if="hasResults">
      <div
        class="ct-listing-list__cards"
        :class="{
          'ct-listing-list__cards--news' : template === 'news',
          'ct-listing-list__cards--resources' : template !== 'news',
        }"
      >
        <template v-if="template === 'news'">
          <ListingPageCardNewsCard
            v-for="(result, index) in results.results"
            :key="index"
            v-bind="result"
            :url="result.url ?? ''"
          />
        </template>
        <template v-else>
          <ListingPageCardResourcesCard
            v-for="(result, index) in results.results"
            :key="index"
            v-bind="result"
          />
        </template>
      </div>
      <PaginationInfinityScroll
        :resetKey
        :total="results.total"
        :totalPages="results.totalPages"
        @requestMore="onRequestMore"
      />
    </template>
    <p
      v-else
      class="ct-listing-list__no-results"
      v-html="textNoResults"
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import ListingPageCardNewsCard from '@/components/ListingPageCard/News/Card.vue'
import ListingPageCardResourcesCard from '@/components/ListingPageCard/Resources/Card.vue'
import PaginationInfinityScroll from '@/components/PaginationInfinityScroll.vue'
import type { ListingResults } from '@/types/backend'

const props = defineProps<{
  resetKey: number
  results: ListingResults
  template: 'news' | 'resources'
  textNoResults: string
}>()

const emit = defineEmits<{ requestMore: [page: number] }>()
const hasResults = computed(() => props.results.total > 0)
const onRequestMore = (page: number) => emit('requestMore', page)
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-listing-list__cards {
  @apply
  grid
  grid-cols-1
  justify-between;
}

.ct-listing-list__cards--news {
  @apply
  md:grid-cols-2
  gap-9;
}

.ct-listing-list__cards--resources {
  @apply
  md:grid-cols-3
  gap-9
  md:gap-0;
}

.ct-listing-list__no-results {
  @apply
  tw-shared-font-hind-siliguri__bold-base-md-xl-grey-black
  text-center
  py-7.5;
}
</style>
