<template>
  <div
    class="ct-listing-page-card-resources-card"
    :class="{ 'ct-listing-page-card-resources-card--link': url }"
  >
    <a
      v-if="url"
      class="ct-listing-page-card-resources-card__link"
      :href="url"
      :title
    >
      <ListingPageCardInfo v-bind="props" />
    </a>
    <ListingPageCardInfo
      v-else
      v-bind="props"
    />
  </div>
</template>

<script setup lang="ts">
import type { ListingPageCardResourcesProps } from '@/types/backend'
import ListingPageCardInfo from '@/components/ListingPageCard/Resources/Info.vue'

type ListingPageCardResources = ListingPageCardResourcesProps
const props = defineProps<ListingPageCardResources>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-listing-page-card-resources-card {
  @apply
  tw-shared-base-flex-col-gap-3
  p-3
  w-full
  md:w-1/2
  lg:w-1/4
  lg:min-h-50;
}

.ct-listing-page-card-resources-card--link {
  @apply
  border
  border-solid
  border-white
  cursor-pointer
  hover:border-theme-grey-dark;
}

.ct-listing-page-card-resources-card__link {
  @apply
  tw-shared-base-flex-col-gap-3
  no-underline;
}

</style>
