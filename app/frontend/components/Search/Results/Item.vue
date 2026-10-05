<template>
  <a
    class="ct-search-results-item"
    :href="url"
    :title="title"
  >
    <div class="ct-search-results-item__content">
      <h3
        class="ct-search-results-item__title"
        v-html="title"
      />
      <p
        v-if="summary"
        class="ct-search-results-item__summary"
        v-html="summary"
      />
    </div>
    <div
      v-if="image && image!=='placeholder_image'"
      class="ct-search-results-item__image"
      :style="{ backgroundImage: `url(${image})` }"
    />
    <div
      v-else
      class="ct-search-results-item__image
      ct-search-results-item__image--placeholder"
    >
      <IconPlaceholderImage class="ct-search-results-item__placeholder" />
    </div>
  </a>
</template>

<script setup lang="ts">
import IconPlaceholderImage from '@/components/Icon/PlaceholderImage.vue'
import type { SearchSiteResult } from '@/types/backend'

defineProps<SearchSiteResult>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-search-results-item {
  @apply
  tw-shared-base-flex-gap-5
  flex-col
  md:flex-row
  justify-between
  no-underline
  p-3
  hover:no-underline
  hover:border
  hover:border-theme-grey
  rounded;
}

.ct-search-results-item__content {
  @apply
  tw-shared-base-flex-col-gap-3
  order-2
  md:order-1;
}

.ct-search-results-item__title {
  @apply tw-shared-font-hind-siliguri__semibold-lg-md-xl-grey-black;
}

.ct-search-results-item__summary {
  @apply tw-shared-font-hind-siliguri__light-base-grey-black;
 }

.ct-search-results-item__image {
  @apply
  tw-shared-image-placeholder
  w-full
  md:w-41.25
  md:h-32.5
  shrink-0
  order-1
  md:order-2;
}

.ct-search-results-item__placeholder {
  @apply
  w-[30%]
  text-white;
}
</style>
