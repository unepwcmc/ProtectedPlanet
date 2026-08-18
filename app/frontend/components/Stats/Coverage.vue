<template>
  <div class="ct-stats-coverage">
    <h2
      class="ct-stats-coverage__title"
      v-text="title"
    />
    <div class="ct-stats-coverage__content">
      <div class="ct-stats-coverage__chart">
        <div class="ct-stats-coverage__square">
          <span
            class="ct-stats-coverage__area"
            :class="`ct-stats-coverage__area--${type}`"
            :style="{
              width: `${squareEdgeLength}%`,
              height: `${squareEdgeLength}%`
            }"
          />
        </div>
      </div>
      <div class="ct-stats-coverage__stat-container">
        <div class="ct-stats-coverage__stat-content--no-gap">
          <span
            class="ct-stats-coverage__number-large"
            v-text="`${protectedPercentage}%`"
          />
          <span v-text="textCoverage" />
        </div>
        <div class="ct-stats-coverage__stat-content">
          <p class="ct-stats-coverage__stat">
            <span
              class="ct-stats-coverage__number"
              v-text="`${protectedKm2}km²`"
            />
            <span
              class="ct-stats-coverage__stat-text"
              v-text="textProtected"
            />
          </p>
          <p class="ct-stats-coverage__stat">
            <span
              class="ct-stats-coverage__number"
              v-text="`${totalKm2}km²`"
            />
            <span
              class="ct-stats-coverage__stat-text"
              v-text="textTotal"
            />
          </p>
        </div>
        <div class="ct-stats-coverage__stat-content">
          <p
            v-if="hasNationalReport"
            class="ct-stats-coverage__stat"
          >
            <span
              class="ct-stats-coverage__number"
              v-text="`${protectedNationalReportWithTwoDecimals}%`"
            />
            <span v-text="`${nationalReportVersion}${textNationalReport}`" />
          </p>
          <div
            v-if="hasPameData"
            class="ct-stats-coverage__subsection"
          >
            <p class="ct-stats-coverage__subtitle">
              PAME
            </p>
            <p class="ct-stats-coverage__stat">
              <span
                class="ct-stats-coverage__number"
                v-text="`${pamePercentage}%`"
              />
              <span v-text="textPameAssessments" />
            </p>
            <p class="ct-stats-coverage__stat">
              <span
                class="ct-stats-coverage__number"
                v-text="`${pameKm2}km²`"
              />
              <span v-text="textPame" />
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { StatsCoverageProps } from '@/types/backend'

type StatsCoverage = StatsCoverageProps
const props = defineProps<StatsCoverage>()

const hasNationalReport = computed(() =>
  props.protectedNationalReport != null && props.nationalReportVersion != null)
const protectedNationalReportWithTwoDecimals = computed(() =>
  hasNationalReport.value ? props.protectedNationalReport!.toFixed(2) : '')
const hasPameData = computed(() => props.pamePercentage != null && props.pameKm2 != null)
const squareEdgeLength = computed(() => Math.sqrt(props.protectedPercentage * 100))
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-stats-coverage {
  @apply
  tw-shared-card-stats
  tw-shared-card-stats-half;
}

.ct-stats-coverage__title {
  @apply tw-shared-list-title;
}

.ct-stats-coverage__content {
  @apply tw-shared-base-flex-col-md-row-gap-5;
}

.ct-stats-coverage__chart {
  @apply w-1/2 md:w-[30%];
}

.ct-stats-coverage__square {
  @apply relative border border-theme-grey-black pt-[100%];
}

.ct-stats-coverage__area {
  @apply block absolute top-0 left-0;
}

.ct-stats-coverage__area--marine {
  @apply bg-theme-blue;
}

.ct-stats-coverage__area--terrestrial {
  @apply bg-theme-bright-green;
}

.ct-stats-coverage__stat-container {
  @apply tw-shared-base-flex-col-gap-3;
}

.ct-stats-coverage__stat-content--no-gap {
  @apply tw-shared-base-flex-col;
}

.ct-stats-coverage__stat-content {
  @apply tw-shared-base-flex-col-gap-3;
}

.ct-stats-coverage__stat {
  @apply tw-shared-base-flex-col;
}

.ct-stats-coverage__number {
  @apply
  tw-shared-font-hind-siliguri__semibold-base-grey-black
  leading-[0.9];
}

.ct-stats-coverage__number-large {
  @apply tw-shared-font-hind-siliguri__semibold-4xl-grey-black
  leading-[0.9];
}

.ct-stats-coverage__stat-text {
  @apply tw-shared-font-hind-siliguri__light-sm-grey-black;
}

.ct-stats-coverage__subsection {
  @apply border-t border-theme-grey-light;
}

.ct-stats-coverage__subtitle {
  @apply tw-shared-font-hind-siliguri__normal-xl;
}
</style>
