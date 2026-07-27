<template>
  <div class="card--stats-iucn card--stats-half">
    <h2
      class="card__h2"
      v-text="title"
    />
    <AmChartPie
      v-if="chart"
      :dataset="chart"
      :doughnut="true"
    />
    <ul class="list--underline theme--governance">
      <li
        v-for="(type, i) in governance"
        :key="i"
        class="list__li"
      >
        <i class="list__icon" />
        <span
          class="list__title"
          v-text="type.governance_name"
        />
        <span
          class="list__value"
          v-text="type.count"
        />
        <a
          class="list__right list__a"
          :href="type.link"
          :title="type.title"
        >
          View list
        </a>
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import AmChartPie from '@/components/AmChart/Pie.vue'
import type { StatsGovernanceProps } from '@/types/backend'

type StatsGovernance = StatsGovernanceProps
defineProps<StatsGovernance>()
</script>
