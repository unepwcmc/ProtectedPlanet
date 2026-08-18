<template>
  <div class="ct-stats-sources">
    <h2
      class="ct-stats-sources__title
      tw-global-pdf-export__break-after-avoid"
      v-text="`${title} ${count}`"
    />
    <ul class="ct-stats-sources__list">
      <li
        v-for="(source, i) in sources"
        :key="i"
        class="ct-stats-sources__item
        tw-global-pdf-export__break-inside-avoid"
      >
        <span
          class="ct-stats-sources__item-title"
          v-text="source.title"
        />
        <span
          class="ct-stats-sources__item-date"
          v-text="`${sourceUpdated}: ${source.date_updated}`"
        />
        <span
          class="ct-stats-sources__item-party"
          v-text="source.resp_party"
        />
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import type { StatsSourcesProps } from '@/types/backend'

type StatsSources = StatsSourcesProps
defineProps<StatsSources>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-stats-sources {
  @apply tw-shared-card-stats;
}

.ct-stats-sources__title {
  @apply tw-shared-list-title;
}

.ct-stats-sources__list {
  @apply
  tw-shared-list-underline-scrollbar
  w-full;
}

.ct-stats-sources__item {
  @apply
  tw-shared-base-flex-col-md-row-gap-1
  border-t
  first:border-t-0
  border-theme-grey-light
  py-3.5
  items-baseline
  md:items-center;
}

.ct-stats-sources__item-title {
  @apply
  tw-shared-list-underline-title
  md:w-[45%];
}

.ct-stats-sources__item-date {
  @apply
  tw-shared-list-underline-value
  md:w-[15%];
}

.ct-stats-sources__item-party {
  @apply
  tw-shared-list-underline-value
  md:w-[40%];
}
</style>
