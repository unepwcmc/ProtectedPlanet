<template>
  <div class="ct-stats-designations">
    <h2
      class="ct-stats-designations__title"
      v-text="title"
    />
    <ChartRowStacked
      v-if="chart"
      :rows="chart"
    />
    <div class="ct-stats-designations__legend">
      <div
        v-for="(designation, i) in designations"
        :key="i"
        class="ct-stats-designations__legend-group pdf-break-inside-avoid"
      >
        <div class="ct-stats-designations__legend-header">
          <span
            class="ct-stats-designations__legend-key"
            :class="`tw-shared-chart-theme-${(i % 12) + 1}`"
          />
          <h3
            class="ct-stats-designations__legend-title"
            v-text="designation.title"
          />
          <span
            class="ct-stats-designations__legend-total"
            v-text="designation.total"
          />
        </div>
        <ul
          v-if="designation.has_jurisdiction"
          class="ct-stats-designations__jurisdictions"
        >
          <li
            v-for="(jurisdiction, j) in designation.jurisdictions"
            :key="j"
            class="ct-stats-designations__jurisdiction"
          >
            <span v-text="jurisdiction.designation_name" />
            <span
              class="ct-stats-designations__jurisdiction-count"
              v-text="jurisdiction.count"
            />
            <a
              class="ct-stats-designations__jurisdiction-link"
              :href="jurisdiction.link"
              :title="jurisdiction.title"
            >
              <IconCircleChevron class="ct-stats-designations__jurisdiction-link-icon" />
            </a>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import ChartRowStacked from '@/components/Chart/RowStacked.vue'
import IconCircleChevron from '@/components/Icon/CircleChevron.vue'
import type { StatsDesignationsProps } from '@/types/backend'

type StatsDesignations = StatsDesignationsProps
defineProps<StatsDesignations>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-stats-designations {
  @apply tw-shared-card-stats;
}

.ct-stats-designations__title {
  @apply mt-0;
}

.ct-stats-designations__legend {
  @apply flex flex-col gap-10 md:grid md:grid-cols-2 md:gap-12;
}

.ct-stats-designations__legend-header {
  @apply flex items-center pr-6.75;
}

.ct-stats-designations__legend-key {
  @apply mr-2 block size-6 shrink-0 rounded-full;
}

.ct-stats-designations__legend-title {
  @apply m-0;
}

.ct-stats-designations__legend-total {
  @apply mr-[3%] ml-auto;
}

.ct-stats-designations__jurisdictions {
  @apply tw-shared-list-underline-scrollbar w-full list-none;
}

.ct-stats-designations__jurisdiction {
  @apply tw-shared-list-underline-item items-start;
}

.ct-stats-designations__jurisdiction-count {
  @apply ml-auto;
}

.ct-stats-designations__jurisdiction-link {
  @apply tw-shared-button-basic shrink-0;
}

.ct-stats-designations__jurisdiction-link-icon {
  @apply size-5.25;
}
</style>
