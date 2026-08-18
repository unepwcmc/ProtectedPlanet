<template>
  <div class="ct-stats-sites">
    <div class="ct-stats-sites__header">
      <h2
        class="ct-stats-sites__title"
        v-text="title"
      />
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
      <CardItem
        v-for="(siteDetail, i) in siteDetails"
        :key="i"
        class="ct-stats-sites__item"
        :image="siteDetail.thumbnail_link"
        :linkTitle="`View more about the site: ${siteDetail.name}`"
        :title="siteDetail.name"
        :url="`/${siteDetail.site_id}`"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import type { StatsSitesProps } from '@/types/backend'
import CardItem from '@/components/Card/Item.vue'
import IconCircleChevron from '@/components/Icon/CircleChevron.vue'

type StatsSites = StatsSitesProps
defineProps<StatsSites>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-stats-sites {
  @apply tw-shared-base-flex-col-gap-3;
}

.ct-stats-sites__header {
  @apply
  flex
  items-center
  justify-between;
}

.ct-stats-sites__title {
  @apply tw-shared-list-title;
}

.ct-stats-sites__view-all {
  @apply tw-shared-button--all;
}

.ct-stats-sites__view-all-icon {
  @apply size-8;
}

.ct-stats-sites__list {
  @apply
  tw-shared-base-flex-gap-6
  flex-wrap
  justify-between;
}

.ct-stats-sites__item:nth-child(3) {
  @apply max-lg:hidden;
}
</style>
