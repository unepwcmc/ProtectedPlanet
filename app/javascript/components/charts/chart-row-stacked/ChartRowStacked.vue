<template>
  <div :class="themeClass">
    <h3 v-if="title" class="chart__title">{{ title }}</h3>

    <ul class="chart__chart ul-unstyled flex">
      <li v-for="(row, index) in rows" :key="`row-${index}`" class="chart__bar flex flex-v-center" :class="themeClass" :style="{ width: row.percent + '%' }">
        <span v-if="row.percent > 0" class="chart__percent">{{ row.percent}}%</span>
      </li>
    </ul>
  </div>
</template>

<script>
  export default {
    name: 'chart-row-stacked',

    props: {
      title: String,
      theme: String,
      rows: {
        type: Array, //[{ percent: Number }]
        required: true
      }
    },

    computed: {
      themeClass () {
        return this.theme ? `theme--${this.theme}` : ''
      }
    }
  }
</script>