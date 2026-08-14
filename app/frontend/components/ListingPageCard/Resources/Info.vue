<template>
  <p
    class="ct-listing-page-card-resources-card-info__date"
    v-html="date"
  />
  <h3
    class="ct-listing-page-card-resources-card-info__title"
    v-html="title"
  />
  <p
    class="ct-listing-page-card-resources-card-info__summary"
    v-html="summary"
  />
  <template v-if="url">
    <a
      v-if="fileUrl"
      class="ct-listing-page-card-resources-card-info__download"
      :href="fileUrl"
      target="_blank"
      :title
    >
      <IconDownload class="ct-listing-page-card-resources-card-info__download-icon" />
    </a>
    <a
      v-if="linkUrl"
      class="ct-listing-page-card-resources-card-info__external-link"
      :href="linkUrl"
      target="_blank"
      :title
    >
      <span v-html="linkTitle" />
      <IconArrowExternal class="ct-listing-page-card-resources-card-info__external-link-icon" />
    </a>
  </template>
</template>

<script setup lang="ts">
import type { ListingPageCardResourcesProps } from '@/types/backend'
import IconDownload from '@/components/Icon/Download.vue'
import IconArrowExternal from '@/components/Icon/ArrowExternal.vue'

type ListingPageCardInfo = ListingPageCardResourcesProps
defineProps<ListingPageCardInfo>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-listing-page-card-resources-card-info__date {
  @apply
  tw-shared-font-hind-siliguri__light-sm-grey
  mt-0;
}

.ct-listing-page-card-resources-card-info__title {
  @apply
  tw-shared-font-hind-siliguri__normal-lg-md-xl-grey-black;
}

.ct-listing-page-card-resources-card-info__summary {
  @apply tw-shared-font-hind-siliguri__leading-1-6-light-base-grey-black;
}

.ct-listing-page-card-resources-card-info__download {
  @apply
  tw-shared-button--bg-theme-primary
  justify-center;
}

.ct-listing-page-card-resources-card-info__download-icon {
  @apply
  w-5
  h-4.75
  text-black;
}

.ct-listing-page-card-resources-card-info__external-link {
  @apply
  flex
  items-center
  tw-shared-font-hind-siliguri__leading-1-6-light-base-grey-black
  underline
  hover:no-underline;
}

.ct-listing-page-card-resources-card-info__external-link-icon {
  @apply
  w-6.25
  h-3
  text-theme-primary;
}
</style>
