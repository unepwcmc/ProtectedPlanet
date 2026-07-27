<template>
  <div class="card--stats-iucn card--stats-half">
    <h2
      class="card__h2"
      v-text="title"
    />
    <AmChartPie
      :dataset="chart"
      :doughnut="true"
    />
    <ul class="list--underline">
      <li
        v-for="(category, i) in categories"
        :key="i"
        class="list__li"
      >
        <i class="list__icon" />
        <span
          class="list__title"
          v-text="`${i + 1}. ${category.iucn_category_name}`"
        />
        <span
          class="list__value"
          v-text="`${category.count}, ${formattedPercentage(category.percentage)}%`"
        />
        <a
          class="list__right list__a"
          :href="category.link"
          :title="category.title"
        >
          View list
        </a>
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import AmChartPie from '@/components/AmChart/Pie.vue'
import type { StatsIucnCategoriesProps } from '@/types/backend'

type StatsIucnCategories = StatsIucnCategoriesProps
defineProps<StatsIucnCategories>()

function formattedPercentage(percentage: number) {
  if (!percentage) return ''

  return Math.round((percentage + Number.EPSILON) * 100) / 100
}
</script>
