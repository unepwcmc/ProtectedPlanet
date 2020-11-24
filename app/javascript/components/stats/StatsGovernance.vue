<template>
  <div class="card--stats-iucn card--stats-half">
    <h2 class="card__h2">{{ data.title }}</h2>

  <am-chart-pie
    v-if="data.chart"
    class="am-chart--pie"
    :dataset="data.chart"
    :doughnut="true"
    id="am-pie-governance-type"
  ></am-chart-pie>

  <ul class="list--underline theme--governance">
    <li 
      class="list__li"
      v-for="(type, i) in data.governance"
      :key="i"
    >
      <i class="list__icon"></i>
      <span class="list__title">{{ type.governance_name}}</span>
      <span class="list__value">{{ type.count }}</span>
      <a 
        href="chart_link(type)[:link]" 
        class="list__right list__a"
        title="chart_link(type)[:title]"
      >
        View list
      </a>
    </li>
  </ul>
</div>
</template>

<script>
import AmChartPie from '../charts/am-chart-pie/AmChartPie'

export default {
  name: 'StatsGovernance',

  components: {
    AmChartPie
  },

  props: {
    data: {
      required: true,
      type: Object
    }
  }
}
</script>