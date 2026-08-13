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
    <h2
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
@reference "#importtailwindcss";

.ct-theme-card {
  @apply
  tw-shared-base-flex-col-gap-6-and-9
  justify-start
  h-120
  lg:h-190
  tw-shared-border-radius
  bg-theme-grey-dark
  bg-cover
  bg-center
  px-8
  pb-8
  text-white
  no-underline;
}

.ct-theme-card__overlay {
  @apply
  absolute
  inset-0
  tw-shared-border-radius
  bg-black/35
  transition-colors
  duration-200;
}

.ct-theme-card:hover .ct-theme-card__overlay {
  @apply bg-black/65;
}

.ct-theme-card__ribbon {
  @apply z-1;
}

.ct-theme-card__title {
  @apply
  z-1
  tw-shared-font-playfair__normal-2xl-md-4xl-white;
}

.ct-theme-card__summary {
  @apply
  z-1
  hidden
  md:block
  tw-shared-font-hind-siliguri__light-base-leading-1-6-grey-black 
  text-white;
}

.ct-theme-card__arrow {
  @apply
  z-1
  size-9
  flex
  items-center
  justify-center
  rounded-full
  bg-white/50;
}

.ct-theme-card__arrow-icon {
  @apply
  size-3.5
  -rotate-90
  text-theme-grey-black;
}
</style>
