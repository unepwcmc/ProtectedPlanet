<template>
  <div
    class="ct-stats-designations
    tw-global-pdf-export__break-inside-avoid"
  >
    <h2
      class="ct-stats-designations__title
      tw-global-pdf-export__break-after-avoid"
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
        class="ct-stats-designations__legend-group
        tw-global-pdf-export__break-inside-avoid"
      >
        <div class="ct-stats-designations__legend-header">
          <span
            class="ct-stats-designations__legend-icon"
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
            class="ct-stats-designations__jurisdiction
            tw-global-pdf-export__break-inside-avoid"
          >
            <span
              class="ct-stats-designations__jurisdiction-name"
              v-text="jurisdiction.designation_name"
            />
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
  @apply tw-shared-list-title;
}

.ct-stats-designations__legend {
  @apply
  tw-shared-base-flex-col-gap-10
  md:grid
  md:grid-cols-2
  md:gap-12;
}

.ct-stats-designations__legend-group {
  @apply tw-shared-base-flex-col-gap-3;
}

.ct-stats-designations__legend-header {
  @apply
  tw-shared-base-flex-gap-3
  items-center
  lg:pr-3;
}

.ct-stats-designations__legend-icon {
  @apply
  tw-shared-list-underline-icon
  size-6;
}

.ct-stats-designations__legend-title {
  @apply tw-shared-font-hind-siliguri__semibold-lg-md-xl-grey-black;
}

.ct-stats-designations__legend-total {
  @apply
  tw-shared-font-hind-siliguri__light-base-grey-black
  ml-auto;
}

.ct-stats-designations__jurisdictions {
  @apply
  tw-shared-list-underline-scrollbar
  w-full
  tw-shared-base-flex-col
  pr-3;
}

.ct-stats-designations__jurisdiction {
  @apply
  tw-shared-list-underline-item;
}

.ct-stats-designations__jurisdiction-name {
  @apply tw-shared-list-underline-value;
}

.ct-stats-designations__jurisdiction-count {
  @apply
  tw-shared-font-hind-siliguri__light-base-grey-black
  ml-auto;
}

.ct-stats-designations__jurisdiction-link {
  @apply
  flex
  tw-shared-button-basic
  shrink-0;
}

.ct-stats-designations__jurisdiction-link-icon {
  @apply tw-shared-list-underline-link-icon;
}
</style>
