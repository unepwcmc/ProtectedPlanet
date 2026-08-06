<template>
  <div :class="themeClass">
    <h3
      v-if="title"
      class="chart__title"
      v-text="title"
    />

    <ul class="chart__chart ul-unstyled flex">
      <li
        v-for="(row, index) in rows"
        :key="`row-${index}`"
        class="chart__bar flex flex-v-center"
        :class="themeClass"
        :style="{ width: `${row.percent}%` }"
      >
        <span
          v-if="row.percent > 0"
          class="chart__percent"
          v-text="`${row.percent}%`"
        />
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { ChartRowStackedProps } from '@/types/backend'

type ChartRowStacked = ChartRowStackedProps
const props = defineProps<ChartRowStacked>()

const themeClass = computed(() => props.theme ? `tw-shared-chart-legend-colour-${props.theme}` : '')
</script>
