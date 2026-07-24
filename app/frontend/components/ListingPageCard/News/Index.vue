<template>
  <div class="cards__cards">
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
