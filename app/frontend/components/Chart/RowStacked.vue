<template>
  <div
    class="ct-chart-row-stacked"
    :class="themeClass"
  >
    <h3
      v-if="title"
      class="ct-chart-row-stacked__title"
      v-text="title"
    />
    <ul class="ct-chart-row-stacked__bars">
      <li
        v-for="(row, index) in rows"
        :key="`row-${index}`"
        class="ct-chart-row-stacked__bar"
        :class="theme ? themeClass : chartThemeClass(index)"
        :style="{ width: `${row.percent}%` }"
      >
        <span
          v-if="row.percent > 0"
          class="ct-chart-row-stacked__percent"
          :class="theme || (index + 1) % 2 !== 0
            ? 'ct-chart-row-stacked__percent--above'
            : 'ct-chart-row-stacked__percent--below'"
          v-text="`${row.percent}%`"
        />
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { chartThemeClass } from '@/constants/charts'
import type { ChartRowStackedProps } from '@/types/backend'

type ChartRowStacked = ChartRowStackedProps
const props = defineProps<ChartRowStacked>()

const themeClass = computed(() => props.theme ? `tw-shared-chart-legend-colour-${props.theme}` : '')
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-chart-row-stacked {
  @apply
  tw-shared-base-flex-col-gap-3
  my-12;
}

.ct-chart-row-stacked__bars {
  @apply
  flex
  w-full
  h-11
  md:h-20.5;
}

.ct-chart-row-stacked__bar {
  @apply
  relative
  h-full;
}

.ct-chart-row-stacked__percent {
  @apply
  absolute
  left-1/2
  flex
  h-7.5
  min-w-10
  -translate-x-1/2
  items-center
  justify-center
  tw-shared-border-radius
  bg-black
  px-1
  text-lg
  font-black
  text-white
  before:absolute
  before:left-1/2
  before:h-0
  before:w-0
  before:-translate-x-1/2
  before:border-x-13
  before:border-x-transparent
  before:content-[''];
}

.ct-chart-row-stacked__percent--above {
  @apply
  bottom-full
  before:top-full
  before:border-t-13
  before:border-t-black;
}

.ct-chart-row-stacked__percent--below {
  @apply
  top-full
  before:bottom-full
  before:border-b-13
  before:border-b-black;
}
</style>
