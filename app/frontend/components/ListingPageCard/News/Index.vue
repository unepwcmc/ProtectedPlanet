<template>
  <div class="ct-listing-page-card-news">
    <ListingPageCardNewsCard
      v-for="(card, index) in cards"
      :key="index"
      v-bind="card"
    />
  </div>
</template>

<script setup lang="ts">
import type { ListingPageCardNewsListProps } from '@/types/backend'
import ListingPageCardNewsCard from '@/components/ListingPageCard/News/Card.vue'

type ListingPageCardNewsList = ListingPageCardNewsListProps
defineProps<ListingPageCardNewsList>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-listing-page-card-news {
  @apply tw-shared-base-flex-col-md-row-gap-6;
}
</style>
