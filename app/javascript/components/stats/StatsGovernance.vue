<template>
  <div class="card--stats-iucn card--stats-half">
    <h2 class="card__h2">{{ title }}</h2>

  <am-chart-pie
    v-if="chart"
    class="am-chart--pie"
    :dataset="chart"
    :doughnut="true"
    id="am-pie-governance-type"
  ></am-chart-pie>

  <ul class="list--underline theme--governance">
    <li 
      class="list__li"
      v-for="(type, i) in governance"
      :key="i"
    >
      <i class="list__icon"></i>
      <span class="list__title">{{ type.governance_name}}</span>
      <span class="list__value">{{ type.count }}</span>
      <a 
        :href="`${type.link}`" 
        class="list__right list__a"
        :title="type.title"
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
    governance: {
      required: true,
      type: Array
    },
    chart: {
      required: true,
      type: Array
    },
    title: {
      required: true,
      type: String
    }
  },
}
</script>