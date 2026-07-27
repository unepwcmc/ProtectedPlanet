<template>
  <div class="chart--row-pa">
    <div class="chart__row">
      <div
        class="chart__bar"
        :class="theme"
        :style="{ width: `${percent}%` }"
      >
        <div
          class="chart__coverage"
          :style="{ width: `${coverage}%` }"
        >
          <span
            class="chart__coverage-label"
            v-text="`${coverage}%`"
          />
        </div>

        <span
          class="chart__bar-label"
          v-text="`${percent}%`"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { ChartRowPaProps } from '@/types/backend'

type ChartRowPa = ChartRowPaProps
defineProps<ChartRowPa>()
</script>
