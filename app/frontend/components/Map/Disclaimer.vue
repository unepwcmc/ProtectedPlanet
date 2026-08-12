<template>
  <div
    v-if="disclaimer"
    class="ct-map-disclaimer"
    :class="{
      'ct-map-disclaimer--country-region-pa': mapiIsForRegionCountryPA
    }"
  >
    <span
      class="ct-map-disclaimer__heading"
      :class="{
        'ct-map-disclaimer__heading--country-region-pa': mapiIsForRegionCountryPA
      }"
      v-text="disclaimer.heading"
    />
    <div
      class="ct-map-disclaimer__body"
      :class="{
        'ct-map-disclaimer__body--country-region-pa': mapiIsForRegionCountryPA
      }"
      v-html="disclaimer.body"
    />
  </div>
</template>

<script setup lang="ts">
import type { MapDisclaimerProps } from '@/types/backend'

type MapDisclaimer = MapDisclaimerProps
withDefaults(defineProps<MapDisclaimer>(), {
  disclaimer: null
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-map-disclaimer {
  @apply
  bg-theme-grey-xdark
  tw-shared-base-flex-col-gap-3;
}

.ct-map-disclaimer--country-region-pa {
  @apply
  p-3
  md:px-5.5
  md:py-3
  bg-white;
}

.ct-map-disclaimer__heading {
  @apply tw-shared-font-hind-siliguri__semi-bold-sm-white;
}

.ct-map-disclaimer__heading--country-region-pa {
  @apply tw-shared-font-hind-siliguri__semi-bold-sm-grey-xdark;
}

.ct-map-disclaimer__body {
  @apply
  tw-shared-font-hind-siliguri__light-sm-white
  overflow-y-auto
  max-h-[14em];
}

.ct-map-disclaimer__body--country-region-pa {
  @apply
  tw-shared-font-hind-siliguri__light-sm-grey-xdark
  overflow-y-auto
  max-h-[14em];
}
</style>
