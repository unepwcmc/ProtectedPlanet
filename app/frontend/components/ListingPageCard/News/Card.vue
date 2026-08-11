<template>
  <a
    class="ct-listing-page-card-news-card"
    :href="url"
  >
    <div
      v-if="image"
      class="ct-listing-page-card-news-card__image"
      :style="{ backgroundImage: `url(${image})` }"
    />
    <div
      v-else
      class="ct-listing-page-card-news-card__image"
    >
      <IconPlaceholderImage class="ct-listing-page-card-news-card__placeholder-icon" />
    </div>
    <div class="ct-listing-page-card-news-card__content">
      <p
        v-if="date"
        class="ct-listing-page-card-news-card__date"
        v-html="date"
      />
      <h3
        class="ct-listing-page-card-news-card__title"
        v-html="title"
      />
      <p
        class="ct-listing-page-card-news-card__summary"
        v-html="summary"
      />
    </div>
  </a>
</template>

<script setup lang="ts">
import type { ListingPageCardNewsProps } from '@/types/backend'
import IconPlaceholderImage from '@/components/Icon/PlaceholderImage.vue'

type ListingPageCardNews = ListingPageCardNewsProps
defineProps<ListingPageCardNews>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-listing-page-card-news-card {
  @apply
  block
  bg-theme-grey-xlight
  w-full
  no-underline
  hover:no-underline;
}

.ct-listing-page-card-news-card__image {
  @apply tw-shared-image-placeholder;
}

.ct-listing-page-card-news-card__placeholder-icon {
  @apply
  w-[30%]
  text-white;
}

.ct-listing-page-card-news-card__content {
  @apply
  py-6.5
  px-5
  md:py-7
  lg:py-7.5
  tw-shared-base-flex-col-gap-3;
}

.ct-listing-page-card-news-card__date {
  @apply tw-shared-font-hind-siliguri__light-sm-grey;
}

.ct-listing-page-card-news-card__title {
  @apply tw-shared-font-hind-siliguri__bold-lg-md-xl-grey-black;
}

.ct-listing-page-card-news-card__summary {
  @apply tw-shared-font-hind-siliguri__light-base-leading-1-6-grey-black;
}
</style>
