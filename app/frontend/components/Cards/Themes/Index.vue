<template>
  <div
    v-if="cards.length"
    class="ct-cards-themes"
  >
    <div
      v-for="(card, index) in cards"
      :key="card.url"
      class="ct-cards-themes__cell"
      :class="{ 'ct-cards-themes__cell--featured': isFeatured(index) }"
    >
      <CarouselThemesCard
        v-bind="card"
        :areaTypeLabel
        :featured="isFeatured(index)"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import type { CarouselThemesProps } from '@/types/backend'
import CarouselThemesCard from '@/components/Carousel/Themes/Card.vue'

type CardsThemes = CarouselThemesProps
defineProps<CardsThemes>()

// Every 3rd card spans the full row at the two-column breakpoint.
const isFeatured = (index: number) => (index + 1) % 3 === 0
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-cards-themes {
  @apply
  tw-shared-base-container
  flex
  flex-wrap
  justify-between
  gap-y-5;
}

.ct-cards-themes__cell {
  @apply
  w-full
  lg:w-[calc(50%-10px)];
}

.ct-cards-themes__cell--featured {
  @apply lg:w-full;
}
</style>
