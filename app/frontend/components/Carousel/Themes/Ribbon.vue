<template>
  <div
    class="ct-carousel-themes-ribbon"
    :class="{
      'ct-carousel-themes-ribbon--hide': pasNo == -1
    }"
  >
    <template v-if="pasNo !== -1">
      <IconPin class="ct-carousel-themes-ribbon__icon" />
      <div class="ct-carousel-themes-ribbon__details">
        <span
          class="ct-carousel-themes-ribbon__number"
          v-text="pasNo"
        />
        <span
          class="ct-carousel-themes-ribbon__label"
          v-text="areaTypeLabel"
        />
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import type { CarouselThemesCardProps } from '@/types/backend'
import IconPin from '@/components/Icon/Pin.vue'

type CarouselThemesCard = CarouselThemesCardProps
defineProps<CarouselThemesCard>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-carousel-themes-ribbon {
  @apply
  tw-shared-base-flex-col
  h-37.5
  w-37.5
  items-center
  justify-between
  bg-theme-grey-black
  px-3
  py-5
  text-center;
}

.ct-carousel-themes-ribbon--hide {
  @apply bg-transparent;
}

.ct-carousel-themes-ribbon__icon {
  @apply
  h-9.5
  w-7
  shrink-0
  text-white;
}

.ct-carousel-themes-ribbon__details {
  @apply tw-shared-base-flex-col-gap-1;
}

.ct-carousel-themes-ribbon__number {
  @apply tw-shared-font-hind-siliguri__bold-xl-md-3xl-lg-4xl-green leading-none;
}

.ct-carousel-themes-ribbon__label {
  @apply
  tw-shared-font-hind-siliguri__normal-base-lg-lg
  text-white;
}

</style>
