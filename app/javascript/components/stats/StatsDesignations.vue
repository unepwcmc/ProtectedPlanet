<template>
  <div class="card--stats-designations">
    <h2 class="card__h2">{{ title }}</h2>

    <div>
      <chart-row-stacked 
        v-if="chart"
        class="chart--row-stacked--designation"
        :rows="chart"
      ></chart-row-stacked>
    </div>
    
    <div class="chart--legend--designation">
      
      <div 
        class="chart__legend-group pdf-break-inside-avoid"
        v-for="(designation, i) in designations"
        :key="i"
      >
        <div class="chart__legend-item">
          <span class="chart__legend-key"></span>
          <h3 class="chart__legend-title">{{ designation.title }}</h3>
          <span class="chart__legend-total">{{ designation.total }}</span>
        </div>

        <ul 
          class="list--underline-scrollbar"
          v-if="designation.has_jurisdiction"
        >
          <li 
            class="list__li flex flex-v-start"
            v-for="(jurisdiction, i) in designation.jurisdictions"
            :key="i"
          >
            <span>{{ jurisdiction.designation_name }}</span>
            <span class="list__right">{{ jurisdiction.count }}</span>
            <a 
              class="list__a"
              :href="`${jurisdiction.link}`"
              :title="jurisdiction.link_title"
            />
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import ChartRowStacked from '../charts/chart-row-stacked/ChartRowStacked.vue'

export default {
  name: 'StatsDesignations',

  components: {
    ChartRowStacked
  },

  props: {
    chart: {
      required: true,
      type: Array
    },
    designations: {
      required: true,
      type: Array
    },
    title: {
      required: true,
      type: String
    }
  }
}
</script>