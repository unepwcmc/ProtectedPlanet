<template>
  <div class="ct-stats-iucn-categories">
    <h2
      class="ct-stats-iucn-categories__title"
      v-text="title"
    />
    <AmChartPie
      :dataset="chart"
      :doughnut="true"
    />
    <ul class="ct-stats-iucn-categories__list">
      <li
        v-for="(category, i) in categories"
        :key="i"
        class="ct-stats-iucn-categories__item"
      >
        <i
          class="ct-stats-iucn-categories__item-icon"
          :class="`tw-shared-chart-theme-${(i % 12) + 1}`"
        />
        <span
          class="ct-stats-iucn-categories__item-title"
          v-text="`${i + 1}. ${category.iucn_category_name}`"
        />
        <span
          class="ct-stats-iucn-categories__item-value"
          v-text="`${category.count}, ${formattedPercentage(category.percentage)}%`"
        />
        <a
          class="ct-stats-iucn-categories__item-link"
          :href="category.link"
          :title="category.title"
        >
          <span class="ct-stats-iucn-categories__item-link-text">View list</span>
          <IconCircleChevron class="ct-stats-iucn-categories__item-link-icon" />
        </a>
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import AmChartPie from '@/components/AmChart/Pie.vue'
import IconCircleChevron from '@/components/Icon/CircleChevron.vue'
import type { StatsIucnCategoriesProps } from '@/types/backend'

type StatsIucnCategories = StatsIucnCategoriesProps
defineProps<StatsIucnCategories>()

function formattedPercentage(percentage: number) {
  if (!percentage) return ''

  return Math.round((percentage + Number.EPSILON) * 100) / 100
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-stats-iucn-categories {
  @apply tw-shared-card-stats tw-shared-card-stats-half;
}

.ct-stats-iucn-categories__title {
  @apply mt-0;
}

.ct-stats-iucn-categories__list {
  @apply list-none;
}

.ct-stats-iucn-categories__item {
  @apply tw-shared-list-underline-item;
}

.ct-stats-iucn-categories__item-icon {
  @apply tw-shared-list-underline-icon block;
}

.ct-stats-iucn-categories__item-title {
  @apply tw-shared-list-underline-title;
}

.ct-stats-iucn-categories__item-value {
  @apply tw-shared-list-underline-value;
}

.ct-stats-iucn-categories__item-link {
  @apply tw-shared-list-underline-link;
}

.ct-stats-iucn-categories__item-link-text {
  @apply tw-shared-list-underline-link-text;
}

.ct-stats-iucn-categories__item-link-icon {
  @apply tw-shared-list-underline-link-icon;
}
</style>
