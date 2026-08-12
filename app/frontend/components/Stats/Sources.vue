<template>
  <div class="ct-stats-sources pdf-break-inside-avoid">
    <h2 v-text="`${title} ${count}`" />

    <div class="ct-stats-sources__content">
      <ol class="ct-stats-sources__list">
        <li
          v-for="(source, i) in sources"
          :key="i"
          class="ct-stats-sources__item"
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
      </ol>
    </div>
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

.ct-stats-sources__content {
  @apply flex flex-col md:flex-row;
}

.ct-stats-sources__list {
  @apply tw-shared-list-underline-scrollbar w-full list-none;
}

.ct-stats-sources__item {
  @apply tw-shared-list-underline-item flex-col md:flex-row;
}

.ct-stats-sources__item-title {
  @apply font-bold mr-2.5 md:w-[45%];
}

.ct-stats-sources__item-date {
  @apply shrink-0 mr-2.5 md:w-[15%];
}

.ct-stats-sources__item-party {
  @apply md:w-[40%];
}
</style>
