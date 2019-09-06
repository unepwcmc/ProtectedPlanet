<template>
  <div class="table__row">
    <p class="table__row-title">
      <a 
        :href="row.url"
        class="table__cell-link"
        :title="`View the statistics page for ${row.title}`"
      >
        {{ row.title }}
      </a>
    </p>
    
    <div class="table__scroll-wrapper">
      <div class="table__scroll">
        <div class="table__cell breakpoint-medium-up">
          <a 
            :href="row.url"
            class="table__cell-link"
            :title="`View the statistics page for ${row.title}`"
          >
            {{ row.title }}
          </a>
        </div>

        <div
          v-for="stat in row.stats"
          class="table__cell"
        >
          <p class="table__cell-title">{{ stat.title }}</p>

          <chart-row-target 
            v-for="(chart, index) in stat.charts"
            :key="getVForKey('row', index)"
            :value="chart.value" 
            :target="chart.target" 
            :title="chart.title" 
            :colour="chart.colour" 
            class="table__cell-chart"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import mixinId from '../../mixins/mixin-ids'
import ChartRowTarget from '../charts/chart-row-target/ChartRowTarget.vue'

export default {
  name: 'Row',

  components: { ChartRowTarget },

  mixins: [ mixinId ],

  props: {
    row: {
      type: Object, // { title: '', url: '', stats: [{ charts: [{ title: '', value: '', target: '', colour: '' }] }] }
      required: true
    }
  }
}
</script>