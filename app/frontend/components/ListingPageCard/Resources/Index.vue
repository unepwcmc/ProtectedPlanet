<template>
  <div
    class="cards__cards"
    :class="{ preview }"
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
