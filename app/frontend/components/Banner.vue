<template>
  <div
    v-if="visible"
    class="banner"
    :class="bannerClass"
    :data-banner-sig="signature"
  >
    <div
      class="banner__container"
      :class="banners.length === 1 ? 'banner__container--single' : 'banner__container--multi'"
    >
      <!-- Single banner -->
      <div
        v-if="banners.length === 1"
        class="banner__content"
      >
        <h3
          v-if="banners[0].title"
          class="banner__title"
        >
          {{ banners[0].title }}
        </h3>
        <div
          class="banner__body"
          v-html="banners[0].content"
        />
      </div>

      <!-- Multiple banners with navigation -->
      <template v-else>
        <button
          class="banner__nav banner__nav--prev"
          aria-label="Previous banner"
          title="Previous"
          @click="previousBanner"
        >
          &#10094;
        </button>

        <div class="banner__slides">
          <div
            v-for="(banner, index) in banners"
            :key="banner.id"
            class="banner__slide"
            :class="{ 'is-active': index === currentIndex }"
            :data-banner-id="banner.id"
          >
            <div class="banner__content">
              <h3
                v-if="banner.title"
                class="banner__title"
              >
                {{ banner.title }}
              </h3>
              <div
                class="banner__body"
                v-html="banner.content"
              />
            </div>
          </div>
        </div>

        <button
          class="banner__nav banner__nav--next"
          aria-label="Next banner"
          title="Next"
          @click="nextBanner"
        >
          &#10095;
        </button>
      </template>

      <button
        class="banner__close"
        aria-label="Close banner"
        @click="closeBanner"
      >
        <span aria-hidden="true">&times;</span>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
// First migrated island (Webpacker/Vue 2 -> Vite/Vue 3). Self-contained: props in,
// local UI state only, no Vuex/$eventHub. Mounted by app/frontend/entrypoints/layout.ts.
import { ref, computed } from 'vue'
import type { BannerProps } from '@/types/backend/banner'

const { banners, signature } = defineProps<BannerProps>()

const currentIndex = ref(0)
const visible = ref(true)

const bannerClass = computed(() => (banners.length === 1 ? '' : 'banner--carousel'))

function nextBanner() {
  currentIndex.value = (currentIndex.value + 1) % banners.length
}

function previousBanner() {
  currentIndex.value = (currentIndex.value - 1 + banners.length) % banners.length
}

function setCookie(name: string, value: string) {
  document.cookie = `${name}=${value}; path=/; max-age=1209600` // 2 weeks
}

function closeBanner() {
  // Set cookie based on single vs multiple banners
  if (banners.length === 1) {
    setCookie('banner_closed', banners[0].id.toString())
  }
  else {
    setCookie('banner_closed_sig', signature)
  }

  // Hide with animation
  visible.value = false
}
</script>

<style scoped>
@reference "tailwindcss";

.banner {
  @apply relative z-100 border-b border-theme-grey-light bg-theme-grey-xlight py-1;
}

.banner__container {
  @apply container flex justify-between gap-5;
}

.banner__container--single {
  @apply items-center;
}

.banner__container--multi {
  @apply items-stretch;
}

.banner__content {
  @apply flex-1;
}

.banner__title {
  @apply mt-0 mb-[0.5em] text-[1.125rem] font-bold leading-[1.3] text-theme-grey-black md:text-[1.25rem];
}

.banner__body {
  @apply text-base leading-[1.3] text-theme-grey-black;
}

/* v-html content has no classes to hook Tailwind onto directly, so it's styled here. */
.banner__body :deep(p) {
  margin: 0;
}

.banner__body :deep(a) {
  @apply text-theme-primary underline;
}

.banner__body :deep(a):hover {
  @apply text-theme-primary-dark no-underline;
}

.banner__nav {
  @apply self-center rounded-[0.3125rem] border border-theme-grey-light bg-transparent px-2 py-1 leading-none text-theme-grey-dark transition-all duration-200 ease-in-out hover:border-theme-primary hover:bg-white hover:text-theme-primary;
}

.banner__slides {
  @apply flex-1 overflow-hidden;
}

.banner__slide {
  @apply hidden;
}

.banner__slide.is-active {
  @apply block;
}

.banner__close {
  @apply shrink-0 rounded-[0.3125rem] bg-transparent p-1 text-2xl leading-none text-theme-grey transition-all duration-200 ease-in-out hover:bg-theme-grey/10 hover:text-theme-grey-dark focus:outline-2 focus:outline-theme-primary focus:outline-offset-2;
}
</style>
