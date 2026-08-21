<template>
  <Swiper
    v-if="cards.length"
    class="ct-carousel-themes"
    v-bind="swiperSettings"
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
import { Swiper, SwiperSlide } from 'swiper/vue'
import { Navigation } from 'swiper/modules'
import 'swiper/css'
import type { CarouselThemesProps } from '@/types/backend'
import CarouselThemesCard from '@/components/Carousel/Themes/Card.vue'
import IconArrow from '@/components/Icon/Arrow.vue'

type CarouselThemes = CarouselThemesProps
defineProps<CarouselThemes>()

const swiperSettings = {
  modules: [Navigation],
  slidesPerView: 1,
  slidesOffsetBefore: 50,
  slidesOffsetAfter: 50,
  spaceBetween: 10,
  loop: true,
  breakpointsBase: 'window',
  navigation: {
    prevEl: '.ct-carousel-themes__button--previous',
    nextEl: '.ct-carousel-themes__button--next'
  },
  breakpoints: {
    768: {
      slidesPerView: 1,
      slidesOffsetBefore: 130,
      slidesOffsetAfter: 130,
      spaceBetween: 20
    },
    1024: {
      slidesPerView: 2,
      slidesOffsetBefore: 80,
      slidesOffsetAfter: 80,
      spaceBetween: 20
    },
    1280: {
      slidesPerView: 2,
      slidesOffsetBefore: 160,
      slidesOffsetAfter: 160,
      spaceBetween: 20
    },
    1440: {
      slidesPerView: 1.95,
      slidesOffsetBefore: 180,
      slidesOffsetAfter: 180,
      spaceBetween: 20
    },
    1600: {
      slidesPerView: 2,
      slidesOffsetBefore: 220,
      slidesOffsetAfter: 220,
      spaceBetween: 20
    },
    1800: {
      slidesPerView: 2,
      slidesOffsetBefore: 350,
      slidesOffsetAfter: 350,
      spaceBetween: 20
    }
  }
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-carousel-themes {
  @apply
  relative
  overflow-hidden;
}

.ct-carousel-themes__cell {
  @apply h-auto;
}

.ct-carousel-themes__button {
  @apply
  absolute
  top-1/2
  z-2
  flex
  items-center
  justify-center
  size-12
  md:size-18
  -translate-y-1/2
  cursor-pointer
  rounded-full
  border-none
  bg-theme-primary
  text-white
  tw-shared-shadow-bottom-grey-light
  transition-colors
  duration-200
  hover:bg-theme-primary-dark;
}

/*
 * Fixed px, matching slidesOffsetBefore/slidesOffsetAfter in <script> at every
 * tier — a % offset scales with container width and drifts out of alignment
 * across a breakpoint's range. Keep these in sync with the JS by hand.
 */
.ct-carousel-themes__button--previous {
  @apply
  left-0
  -translate-x-1/2;

  margin-left: 45px;
}

.ct-carousel-themes__button--next {
  @apply
  right-0
  translate-x-1/2;

  margin-right: 45px;
}

@media (width >= 48rem) {
  .ct-carousel-themes__button--previous {
    margin-left: 120px;
  }

  .ct-carousel-themes__button--next {
    margin-right: 120px;
  }
}

@media (width >= 64rem) {
  .ct-carousel-themes__button--previous {
    margin-left: 70px;
  }

  .ct-carousel-themes__button--next {
     margin-right: 70px;
    }
}

@media (width >= 80rem) {
  .ct-carousel-themes__button--previous {
    margin-left: 170px;
  }

  .ct-carousel-themes__button--next {
     margin-right: 140px;
    }
}

@media (width >= 100rem) {
  .ct-carousel-themes__button--previous {
    margin-left: 210px;
  }

  .ct-carousel-themes__button--next {
    margin-right: 210px;
  }
}

@media (width >= 112.5rem) {
  .ct-carousel-themes__button--previous {
    margin-left: 340px;
  }

  .ct-carousel-themes__button--next {
    margin-right: 340px;
   }
}

.ct-carousel-themes__button-icon {
  @apply
  size-8
  md:h-6
  md:w-6;
}

.ct-carousel-themes__button-icon--previous {
  @apply rotate-90;
}

.ct-carousel-themes__button-icon--next {
  @apply -rotate-90;
}
</style>
