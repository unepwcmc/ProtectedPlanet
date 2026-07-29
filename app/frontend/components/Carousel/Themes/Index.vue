<template>
  <Swiper
    v-if="cards.length"
    class="ct-carousel-themes"
    :modules="[Navigation]"
    :loop="cards.length > 1"
    breakpoints-base="window"
    :slidesPerView="1.1"
    :slidesOffsetBefore="50"
    :spaceBetween="10"
    :breakpoints="{
      768:{
        slidesPerView: 1.2,
        slidesOffsetBefore: 130,
        spaceBetween: 20
      },
      1024: {
        slidesPerView: 2.2,
        slidesOffsetBefore: 80,
        spaceBetween: 20
      },
      1280: {
        slidesPerView: 2.3,
        slidesOffsetBefore: 160,
        spaceBetween: 20
      }
    }"
    :navigation="navigationConfig"
  >
    <SwiperSlide
      v-for="card in cards"
      :key="card.url"
      class="ct-carousel-themes__cell"
    >
      <CarouselThemesCard
        v-bind="card"
        :areaTypeLabel
      />
    </SwiperSlide>
    <button
      class="ct-carousel-themes__button
      ct-carousel-themes__button--previous"
      type="button"
      aria-label="Previous slide"
    >
      <IconArrow
        class="ct-carousel-themes__button-icon
       ct-carousel-themes__button-icon--previous"
      />
    </button>
    <button
      class="ct-carousel-themes__button
      ct-carousel-themes__button--next"
      type="button"
      aria-label="Next slide"
    >
      <IconArrow
        class="ct-carousel-themes__button-icon
      ct-carousel-themes__button-icon--next"
      />
    </button>
  </Swiper>
</template>

<script setup lang="ts">
// Swiper's `loop: true` is the real, battle-tested equivalent of Flickity's
// `wrapAround: true` ("at the end of cells, wrap-around to the other end for
// infinite scrolling") — a hand-rolled clone-buffer-and-silent-snap
// reimplementation of that same behaviour hit real-browser CSS-transition
// timing bugs twice (see git history), so this wave uses Swiper instead.
import { Swiper, SwiperSlide } from 'swiper/vue'
import { Navigation } from 'swiper/modules'
import 'swiper/css'
import type { CarouselThemesProps } from '@/types/backend'
import CarouselThemesCard from '@/components/Carousel/Themes/Card.vue'
import IconArrow from '@/components/Icon/Arrow.vue'

type CarouselThemes = CarouselThemesProps
defineProps<CarouselThemes>()

// Selector strings (not element refs): Swiper resolves these by querying
// within its own root element (see navigation.mjs's `getEl`), so this is
// scoped to this carousel's own prev/next buttons — rendered as this
// component's own non-slide children, per Swiper's documented pattern for
// custom navigation markup — regardless of when Vue would otherwise set a
// sibling template ref during mounting.
const navigationConfig = {
  prevEl: '.ct-carousel-themes__button--previous',
  nextEl: '.ct-carousel-themes__button--next'
}
</script>

<style scoped lang="css">
@reference "tailwindcss";

.ct-carousel-themes {
  @apply relative overflow-hidden;
}

/*
 * No width override here on purpose: with a numeric `slidesPerView` (set on
 * the <Swiper> above, responsive via `breakpoints`), Swiper computes each
 * slide's width itself and sets it as an inline style — which always wins
 * over any CSS class rule regardless of specificity or stylesheet load
 * order. That's also why numeric slidesPerView was chosen over
 * `slidesPerView: 'auto'` + a CSS-driven width: 'auto' mode reads the width
 * from CSS instead of setting it, which hit a real specificity collision
 * with Swiper's own `.swiper-slide { width: 100% }` base rule (see git
 * history) — not an issue here since Swiper itself now owns the value.
 */
.ct-carousel-themes__cell {
  @apply h-auto;
}

.ct-carousel-themes__button {
  @apply absolute top-1/2 z-2 flex h-12 w-12 md:h-18 md:w-18 -translate-y-1/2 cursor-pointer items-center justify-center rounded-full border-none bg-theme-primary text-white shadow-md transition-colors duration-200 hover:bg-theme-primary-dark;
}

/*
 * Inset from the true left/right edge so the button sits roughly on the seam
 * between the fully-visible cards and the partially-visible ("peek") card
 * beside them, rather than jammed against the carousel's outer edge —
 * matching the reference screenshots. These are approximate insets, not
 * derived from `slidesPerView`/`spaceBetween` above — tune per breakpoint if
 * the seam drifts once real card counts/widths are visible live.
 */
.ct-carousel-themes__button--previous {
  @apply left-0 -translate-x-1/2 ml-[9%] md:ml-[14%] lg:ml-[6.5%] xl:ml-[10%];

}

.ct-carousel-themes__button--next {
  @apply right-0 translate-x-1/2 mr-[7.5%] md:mr-[13%] lg:mr-[7.5%] xl:mr-[11%];

}

.ct-carousel-themes__button-icon {
  @apply h-3 w-3 md:h-6 md:w-6;
}

.ct-carousel-themes__button-icon--previous {
  @apply rotate-90;
}

.ct-carousel-themes__button-icon--next {
  @apply -rotate-90;
}
</style>
