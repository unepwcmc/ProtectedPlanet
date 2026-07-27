<template>
  <div class="card--stats-designations">
    <h2
      class="card__h2"
      v-text="title"
    />
    <ChartRowStacked
      v-if="chart"
      class="chart--row-stacked--designation"
      :rows="chart"
    />
    <div class="chart--legend--designation">
      <div
        v-for="(designation, i) in designations"
        :key="i"
        class="chart__legend-group pdf-break-inside-avoid"
      >
        <div class="chart__legend-item">
          <span class="chart__legend-key" />
          <h3
            class="chart__legend-title"
            v-text="designation.title"
          />
          <span
            class="chart__legend-total"
            v-text="designation.total"
          />
        </div>
        <ul
          v-if="designation.has_jurisdiction"
          class="list--underline-scrollbar"
        >
          <li
            v-for="(jurisdiction, j) in designation.jurisdictions"
            :key="j"
            class="list__li flex flex-v-start"
          >
            <span v-text="jurisdiction.designation_name" />
            <span
              class="list__right"
              v-text="jurisdiction.count"
            />
            <a
              class="list__a"
              :href="jurisdiction.link"
              :title="jurisdiction.title"
            />
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import ChartRowStacked from '@/components/Chart/RowStacked.vue'
import type { StatsDesignationsProps } from '@/types/backend'

type StatsDesignations = StatsDesignationsProps
defineProps<StatsDesignations>()
</script>
