<template>
  <a
    class="ct-theme-card"
    :href="url"
    :title="linkTitle"
    :style="{ backgroundImage: `url('${imageUrl}')` }"
  >
    <div class="ct-theme-card__overlay" />

    <CarouselThemesRibbon
      v-bind="props"
      class="ct-theme-card__ribbon"
    />

    <h3
      class="ct-theme-card__title"
      v-text="label"
    />
    <span
      class="ct-theme-card__summary"
      v-html="summary"
    />
    <span class="ct-theme-card__arrow">
      <IconArrow class="ct-theme-card__arrow-icon" />
    </span>
  </a>
</template>

<script setup lang="ts">
import type { CarouselThemesCardProps } from '@/types/backend'
import CarouselThemesRibbon from '@/components/Carousel/Themes/Ribbon.vue'
import IconArrow from '@/components/Icon/Arrow.vue'

type CarouselThemesCard = CarouselThemesCardProps
const props = defineProps<CarouselThemesCard>()
</script>

<style scoped lang="css">
@reference "tailwindcss";

.ct-theme-card {
  @apply
  flex
  flex-col
  gap-3
  h-120
  lg:h-190
  justify-start
  rounded-[5px]
  bg-theme-grey-dark
  bg-cover
  bg-center
  px-8
  pb-8
  text-white
  no-underline;
}

.ct-theme-card__overlay {
  @apply absolute inset-0 rounded-[5px] bg-black/35 transition-colors duration-200;
}

.ct-theme-card:hover .ct-theme-card__overlay {
  @apply bg-black/65;
}

.ct-theme-card__ribbon {
  @apply z-1;
}

.ct-theme-card__title {
  @apply z-1 text-xl leading-tight font-bold;
}

.ct-theme-card__summary {
  @apply z-1 hidden md:block text-base leading-normal;
}

.ct-theme-card__arrow {
  @apply z-1 flex h-9 w-9 items-center justify-center rounded-full bg-white/90;
}

.ct-theme-card__arrow-icon {
  @apply h-2.5 w-2.5 -rotate-90 text-theme-grey-black;
}
</style>
