<template>
  <div
    class="ct-banner-content"
    :class="{ 'ct-banner-content--is-active': isActive }"
    :dataBannerId="data.id"
  >
    <h3
      v-if="data.title"
      class="ct-banner-content__title"
      v-html="data.title"
    />
    <div
      class="ct-banner-content__body"
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
  @apply tw-shared-base-flex-col-gap-1;
}

.ct-banner-content__title {
  @apply tw-shared-font-hind-siliguri__semibold-lg-md-xl-grey-black;
}

:deep(.ct-banner-content__body) {
  @apply tw-shared-cms-wysiwyg;
}
</style>
