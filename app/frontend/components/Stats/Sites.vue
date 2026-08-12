<template>
  <div class="ct-stats-sites">
    <div class="ct-stats-sites__header">
      <h2 v-text="title" />
      <a
        class="ct-stats-sites__view-all"
        :href="viewAll"
        :title="textViewAll"
      >
        {{ textViewAll }}
        <IconCircleChevron class="ct-stats-sites__view-all-icon" />
      </a>
    </div>

    <div class="ct-stats-sites__list">
      <a
        v-for="(siteDetail, i) in siteDetails"
        :key="i"
        class="ct-stats-sites__item"
        :href="`/${siteDetail.site_id}`"
        :title="`View more about the site: ${siteDetail.name}`"
      >
        <div
          class="ct-stats-sites__item-image"
          :style="{ backgroundImage: `url(${siteDetail.thumbnail_link})` }"
        />

        <div class="ct-stats-sites__item-content">
          <h3
            class="ct-stats-sites__item-title"
            v-text="siteDetail.name"
          />
        </div>
      </a>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { StatsSitesProps } from '@/types/backend'
import IconCircleChevron from '@/components/Icon/CircleChevron.vue'

type StatsSites = StatsSitesProps
defineProps<StatsSites>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-stats-sites__header {
  @apply flex items-center justify-between;
}

.ct-stats-sites__view-all {
  @apply
  tw-shared-button--all
  ml-3.5;
}

.ct-stats-sites__view-all-icon {
  @apply size-8.5 ml-2.5;
}

.ct-stats-sites__list {
  @apply flex flex-wrap justify-between;
}

.ct-stats-sites__item {
  @apply
  tw-shared-shadow-grey-light
  flex
  flex-col
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

/* legacy `.preview .card__link:nth-child(3)` — this component only ever renders the "preview"
   variant, so the modifier is unconditional here. */
.ct-stats-sites__item:nth-child(3) {
  @apply max-md:hidden;
}

/* legacy trailing-lone-item centering hack for a 3-column grid with a leftover 2nd-of-3 row */
.ct-stats-sites__item:not(:first-child, :nth-child(3n+1), :nth-child(3n)):last-child {
  @apply ml-[5%] mr-auto;
}

.ct-stats-sites__item-image {
  @apply tw-shared-image-placeholder h-38.75 w-full;
}

.ct-stats-sites__item-content {
  @apply mt-3 text-lg;
}

.ct-stats-sites__item-title {
  @apply tw-shared-font-hind-siliguri__bold-xl-grey-black;
}
</style>
