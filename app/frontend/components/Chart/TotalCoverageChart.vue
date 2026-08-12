<template>
  <div class="ct-total-coverage-chart">
    <div class="ct-total-coverage-chart__row">
      <div
        class="ct-total-coverage-chart__total-bar"
        :class="total.legend_colour_class"
        :style="{ width: `${total.value}%` }"
      >
        <div
          class="ct-total-coverage-chart__coverage-bar"
          :class="coverage.legend_colour_class"
          :style="{ width: `${coverage.value}%` }"
        >
          <span
            class="ct-total-coverage-chart__label
            ct-total-coverage-chart__label--coverage"
            v-text="`${coverage.value}%`"
          />
        </div>
        <span
          class="ct-total-coverage-chart__label
          ct-total-coverage-chart__label--total"
          v-text="`${total.value}%`"
        />
      </div>
    </div>
    <ul class="ct-total-coverage-chart__legends">
      <li
        v-for="(item, index) in [coverage, total]"
        :key="index"
        class="ct-total-coverage-chart__legend"
      >
        <span
          class="ct-total-coverage-chart__legend-key"
          :class="item.legend_colour_class"
        />
        <span v-text="item.title" />
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import type { ChartTotalCoverageChartProps } from '@/types/backend'

type ChartTotalCoverageChart = ChartTotalCoverageChartProps
const { total, coverage } = defineProps<ChartTotalCoverageChart>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-total-coverage-chart {
  @apply
  py-10
  tw-shared-base-flex-col-gap-12;
}

.ct-total-coverage-chart__row {
  @apply h-13 bg-white;
}

.ct-total-coverage-chart__total-bar {
  @apply
  relative
  flex h-13
  items-center
  justify-between;
}

.ct-total-coverage-chart__coverage-bar {
  @apply
  relative
  h-13;
}

.ct-total-coverage-chart__label {
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

.ct-total-coverage-chart__label--total {
  @apply
  top-[calc(100%+2px)]
  before:bottom-full
  before:border-b-13
  before:border-b-black;
}

.ct-total-coverage-chart__label--coverage {
  @apply
  bottom-[calc(100%+2px)]
  before:top-full
  before:border-t-13
  before:border-t-black;
}

.ct-total-coverage-chart__legends {
  @apply
  tw-shared-base-flex-col-gap-6
  text-sm
  md:flex-row;
}

.ct-total-coverage-chart__legend {
  @apply
  tw-shared-base-flex-gap-2
  tw-shared-font-hind-siliguri__normal-sm-grey-black
  items-center;
}

.ct-total-coverage-chart__legend-key {
  @apply
  block
  size-4
  shrink-0
  rounded-full
  md:size-6;
}
</style>
