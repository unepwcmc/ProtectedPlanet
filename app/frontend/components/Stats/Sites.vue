<template>
  <div>
    <div class="flex flex-v-center flex-h-between">
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

    <div class="cards--search-results-areas preview">
      <a
        v-for="(siteDetail, i) in siteDetails"
        :key="i"
        class="card__link"
        :href="`/${siteDetail.site_id}`"
        :title="`View more about the site: ${siteDetail.name}`"
      >
        <div class="card__image-placeholder">
          <div
            class="card__image"
            :style="{ backgroundImage: `url(${siteDetail.thumbnail_link})` }"
          />
        </div>

        <div class="card__content">
          <h3
            class="card__title"
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

.ct-stats-sites__view-all {
  @apply
  tw-shared-button--all
  ml-3.5;
}

.ct-stats-sites__view-all-icon {
  @apply size-8.5 ml-2.5;
}
</style>
