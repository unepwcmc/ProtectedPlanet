<template>
  <a
    class="ct-search-areas-results-item"
    :class="`ct-search-areas-results-item--${geoType}`"
    :href="url"
  >
    <div
      v-if="image"
      class="ct-search-areas-results-item__image"
      :style="{ backgroundImage: `url(${image})` }"
    />
    <div
      v-else
      class="ct-search-areas-results-item__image"
    >
      <IconPlaceholderImage class="ct-search-areas-results-item__placeholder-icon" />
    </div>
    <div class="ct-search-areas-results-item__content">
      <h3
        class="ct-search-areas-results-item__title"
        v-html="title"
      />
      <span
        v-if="totalAreas"
        class="ct-search-areas-results-item__total-areas"
        v-html="totalAreas"
      />
    </div>
  </a>
</template>

<script setup lang="ts">
import IconPlaceholderImage from '@/components/Icon/PlaceholderImage.vue'

defineProps<{
  geoType: string
  image?: string
  countryFlag?: string
  totalAreas?: string
  title: string
  url: string
}>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-search-areas-results-item {
  @apply
  tw-shared-shadow-grey-light
  tw-shared-base-flex-col-gap-3
  w-full
  md:w-[48%]
  lg:w-[31.5%]
  h-auto
  md:h-90
  min-h-70
  mb-7.5
  bg-white
  px-4.5
  pt-4.5
  pb-4
  no-underline
  hover:no-underline;
}

.ct-search-areas-results-item__image {
  @apply
  tw-shared-image-placeholder
  h-38.75;
}

.ct-search-areas-results-item__placeholder-icon {
  @apply
  w-[30%]
  text-white;
}

.ct-search-areas-results-item__content {
  @apply tw-shared-base-flex-col-gap-1;
}

.ct-search-areas-results-item__title {
  @apply tw-shared-font-hind-siliguri__bold-xl-grey-black;
}

.ct-search-areas-results-item__total-areas {
  @apply tw-shared-font-hind-siliguri__normal-lg-grey-black;
}
</style>
