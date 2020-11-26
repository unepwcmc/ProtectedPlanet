<template>
  <div class="card--stats-iucn card--stats-half">
    <h2 class="card__h2">{{ title }}</h2>

  <am-chart-pie
    class="am-chart--pie"
    :dataset="chart"
    :doughnut="true"
    id="am-pie-iucn-categories"
  ></am-chart-pie>

  <ul class="list--underline">
    <li 
      class="list__li"
      v-for="(category, i) in categories"
      :key="i"
    >
      <i class="list__icon"></i>
      <span class="list__title">{{ i+1 }}. {{ category.iucn_category_name}}</span>
      <span class="list__value">
        {{ category.count }}, {{ category.percentage | decimals }}%
      </span>
      <a 
        :href="`${category.link}`"  
        class="list__right list__a"
        :title="category.title"
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
  name: 'StatsIucnCategories',

  components: {
    AmChartPie
  },

  props: {
    categories: {
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

  filters: {
    decimals(percentage) {
      if (!percentage) return ''
      
      return Math.round((Number(percentage) + Number.EPSILON) * 100) / 100
    }
  }
}
</script>