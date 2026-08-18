<template>
  <div
    class="ct-listing-page-card-resources"
    :class="{ 'ct-listing-page-card-resources--preview': preview }"
  >
    <ListingPageCardResourcesCard
      v-for="(card, index) in cards"
      :key="index"
      v-bind="card"
    />
  </div>
</template>

<script setup lang="ts">
import type { ListingPageCardResourcesListProps } from '@/types/backend'
import ListingPageCardResourcesCard from '@/components/ListingPageCard/Resources/Card.vue'

type ListingPageCardResourcesList = ListingPageCardResourcesListProps
defineProps<ListingPageCardResourcesList>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-listing-page-card-resources {
  @apply tw-shared-base-flex-col-md-row-gap-1;
}

.ct-listing-page-card-resources--preview > :nth-child(3),
.ct-listing-page-card-resources--preview > :nth-child(4) {
  @apply hidden lg:block;
}
</style>
