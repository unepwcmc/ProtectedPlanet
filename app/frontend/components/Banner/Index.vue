<template>
  <div
    v-if="isVisible"
    class="ct-banner"
  >
    <div class="ct-banner__container">
      <button
        v-if="hasMultipleBanners"
        class="ct-banner__nav banner__nav--prev"
        @click="previousBanner"
      >
        &#10094;
      </button>
      <div class="ct-banner__slides">
        <template v-if="hasMultipleBanners">
          <BannerContent
            v-for="(banner, index) in banners"
            :key="`${banner.id}BannerContent`"
            class="ct-banner__slide"
            :data="banner"
            :isActive="index === currentIndex"
          />
        </template>
        <BannerContent
          v-else
          :data="banners[0]"
          :isActive="true"
        />
      </div>
      <button
        v-if="hasMultipleBanners"
        class="ct-banner__nav banner__nav--next"
        @click="nextBanner"
      >
        &#10095;
      </button>
      <button
        class="ct-banner__close"
        @click="closeBanner"
      >
        <IconClose class="ct-banner__icon" />
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import type { BannerProps } from '@/types/backend'
import BannerContent from '@/components/Banner/Content.vue'
import IconClose from '@/components/Icon/Close.vue'

type Banner = BannerProps
const props = defineProps<Banner>()

const currentIndex = ref(0)
const isVisible = ref(true)

const hasMultipleBanners = computed(() => props.banners.length > 1)

function nextBanner() {
  currentIndex.value = (currentIndex.value + 1) % props.banners.length
}

function previousBanner() {
  currentIndex.value = (currentIndex.value - 1 + props.banners.length) % props.banners.length
}

function setCookie(name: string, value: string) {
  document.cookie = `${name}=${value}; path=/; max-age=1209600` // 2 weeks
}

function closeBanner() {
  if (props.banners.length === 1) {
    setCookie('banner_closed', props.banners[0].id.toString())
  }
  else {
    setCookie('banner_closed_sig', props.signature)
  }

  isVisible.value = false
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-banner {
  @apply
  flex
  items-center
  justify-center
  border-b
  border-b-theme-grey-light
  bg-theme-grey-xlight
  py-3;
}

.ct-banner__container {
  @apply
  tw-shared-base-container
  tw-shared-base-flex-gap-5
  justify-between ;
}

.ct-banner__slides {
  @apply
  flex
  flex-1
  items-center;
}

.ct-banner__nav {
  @apply
  self-center
  tw-shared-border-radius
  border
  border-theme-grey-light
  bg-transparent
  px-2
  py-1
  leading-none
  text-theme-grey-dark
  transition-all
  duration-200
  ease-in-out
  hover:border-theme-primary
  hover:bg-white
  hover:text-theme-primary;
}

.ct-banner__close {
  @apply
  flex
  items-center
  p-2
  cursor-pointer
  bg-none
  hover:bg-theme-grey/10;
}

.ct-banner__icon {
  @apply
  shrink-0
  size-3
  text-theme-grey
  hover:text-theme-grey-dark;
}
</style>
