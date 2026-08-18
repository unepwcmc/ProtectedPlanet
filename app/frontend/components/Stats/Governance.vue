<template>
  <div class="ct-stats-governance">
    <h2
      class="ct-stats-governance__title
      tw-global-pdf-export__break-after-avoid"
      v-text="title"
    />
    <AmChartPie
      v-if="chart"
      :dataset="chart"
      :doughnut="true"
    />
    <ul class="ct-stats-governance__list">
      <li
        v-for="(type, i) in governance"
        :key="i"
        class="ct-stats-governance__item
        tw-global-pdf-export__break-inside-avoid"
      >
        <i
          class="ct-stats-governance__item-icon"
          :class="`tw-shared-chart-theme-${(i % 12) + 1}`"
        />
        <span
          class="ct-stats-governance__item-title"
          v-text="type.governance_name"
        />
        <span
          class="ct-stats-governance__item-value"
          v-text="type.count"
        />
        <a
          class="ct-stats-governance__item-link"
          :href="type.link"
          :title="type.title"
        >
          <span class="ct-stats-governance__item-link-text">View list</span>
          <IconCircleChevron class="ct-stats-governance__item-link-icon" />
        </a>
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import AmChartPie from '@/components/AmChart/Pie.vue'
import IconCircleChevron from '@/components/Icon/CircleChevron.vue'
import type { StatsGovernanceProps } from '@/types/backend'

type StatsGovernance = StatsGovernanceProps
defineProps<StatsGovernance>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-stats-governance {
  @apply
  tw-shared-card-stats
  tw-shared-card-stats-half;
}

.ct-stats-governance__title {
  @apply tw-shared-list-title;
}

.ct-stats-governance__list {
  @apply tw-shared-base-flex-col;
}

.ct-stats-governance__item {
  @apply tw-shared-list-underline-item;
}

.ct-stats-governance__item-icon {
  @apply tw-shared-list-underline-icon;
}

.ct-stats-governance__item-title {
  @apply tw-shared-list-underline-title;
}

.ct-stats-governance__item-value {
  @apply tw-shared-list-underline-value;
}

.ct-stats-governance__item-link {
  @apply tw-shared-list-underline-link;
}

.ct-stats-governance__item-link-text {
  @apply tw-shared-list-underline-link-text;
}

.ct-stats-governance__item-link-icon {
  @apply tw-shared-list-underline-link-icon;
}
</style>
