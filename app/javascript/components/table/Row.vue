<template>
  <div class="table__row">
    <p class="table__row-title">{{ row.title }}</p>
    
    <div class="table__scroll-wrapper">
      <div class="table__scroll">
        <div class="table__cell breakpoint-medium-up">
          <a :href="row.url">{{ row.title }}</a>
        </div>

        <div
          v-for="stat in row.stats"
          class="table__cell"
        >
          <p class="table__cell-title">{{ stat.title }}</p>

          <chart-row-target 
            v-for="(chart, index) in stat.charts"
            :value="chart.value" 
            :target="chart.target" 
            :title="chart.title" 
            :colour="chart.colour" 
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import ChartRowTarget from '../charts/chart-row-target/ChartRowTarget.vue'

export default {
  name: 'Row',

  components: { ChartRowTarget },

  props: {
    row: {
      type: Object, // { title: '', url: '', stats: [{ charts: [{ title: '', value: '', target: '', colour: '' }] }] }
      required: true
    }
  }
}
</script>