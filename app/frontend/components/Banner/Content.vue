<template>
  <div
    class="ct-banner-content"
    :class="{ 'ct-banner-content--is-active': isActive }"
    :dataBannerId="data.id"
  >
    <h3
      v-if="data.title"
      class="ct-banner__title"
      v-html="data.title"
    />
    <div
      class="ct-banner__body"
      v-html="data.content"
    />
  </div>
</template>

<script setup lang="ts">
import type { Banner } from '@/types/backend'

defineProps<{
  data: Banner
  isActive: boolean
}>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-banner-content {
  @apply hidden;
}

.ct-banner-content--is-active {
  @apply block;
}

.ct-banner-content__title {
  @apply mt-0 mb-[0.5em] text-[1.125rem] font-bold leading-[1.3] text-theme-grey-black md:text-[1.25rem];
}

.ct-banner-content__body {
  @apply text-base leading-[1.3] text-theme-grey-black;
}
</style>
