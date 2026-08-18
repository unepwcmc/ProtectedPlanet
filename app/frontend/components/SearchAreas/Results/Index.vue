<template>
  <div class="ct-search-areas-results">
    <template v-if="hasResults">
      <h2
        class="ct-search-areas-results__title"
        v-text="`${results.title} (${totalAsString})`"
      />
      <div class="ct-search-areas-results__grid">
        <CardItem
          v-for="(area, index) in results.areas"
          :key="index"
          hasSecondaryLine
          :image="area.image"
          :modifier="results.geoType"
          :secondaryText="area.totalAreas"
          titleIsHtml
          :title="area.title"
          :url="area.url"
        />
      </div>
      <PaginationInfinityScroll
        :triggerClass="smTriggerElement"
        :total="results.total"
        :totalPages="results.totalPages"
        :resetKey
        @requestMore="requestMore"
      />
    </template>
    <p
      v-else
      class="ct-search-areas-results__none"
      v-html="noResultsText"
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import CardItem from '@/components/Card/Item.vue'
import PaginationInfinityScroll from '@/components/PaginationInfinityScroll.vue'
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

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-search-areas-results {
  @apply tw-shared-base-flex-col-gap-6;
}

.ct-search-areas-results__grid {
  @apply
  flex
  flex-wrap
  justify-between;
}

.ct-search-areas-results__title {
  @apply tw-shared-font-playfair__semi-bold-xl-md-2xl-grey-black;
}

.ct-search-areas-results__none {
  @apply
  tw-shared-font-hind-siliguri__normal-xl
  text-center
  py-7.5;
}
</style>
