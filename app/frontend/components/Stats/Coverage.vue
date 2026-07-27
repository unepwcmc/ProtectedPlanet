<template>
  <div class="card--stats-coverage card--stats-half">
    <h2
      class="card__h2"
      v-text="title"
    />
    <div class="card__content">
      <div class="card__chart">
        <div class="chart--square">
          <span
            class="chart__area"
            :class="`theme--${type}`"
            :style="{
              width: `${squareEdgeLength}%`,
              height: `${squareEdgeLength}%`
            }"
          />
        </div>
      </div>
      <div>
        <div class="card__stat-large">
          <span
            class="card__number-large block"
            v-text="`${protectedPercentage}%`"
          />
          <span v-text="textCoverage" />
        </div>
        <div>
          <p class="card__stat">
            <span
              class="card__number block"
              v-text="`${protectedKm2}km²`"
            />
            <span v-text="textProtected" />
          </p>
          <p class="card__stat">
            <span
              class="card__number block"
              v-text="`${totalKm2}km²`"
            />
            <span v-text="textTotal" />
          </p>
        </div>
        <div>
          <p
            v-if="hasNationalReport"
            class="card__stat"
          >
            <span
              class="card__number block"
              v-text="`${protectedNationalReportWithTwoDecimals}%`"
            />
            <span v-text="`${nationalReportVersion}${textNationalReport}`" />
          </p>
          <div
            v-if="hasPameData"
            class="card__subsection"
          >
            <p class="card__subtitle">
              PAME
            </p>
            <p class="card__stat">
              <span
                class="card__number block"
                v-text="`${pamePercentage}%`"
              />
              <span v-text="textPameAssessments" />
            </p>
            <p class="card__stat">
              <span
                class="card__number block"
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
