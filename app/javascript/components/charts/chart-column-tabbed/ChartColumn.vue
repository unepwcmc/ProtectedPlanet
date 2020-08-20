<template>
  <div class="chart--column">
    <div 
      v-for="(column, index) in columns"
      class="chart__column"
      :key="index"
    >
      <div class="chart__bar">
        <span class="chart__coverage" :style="{ height: column.percentage + '%' }" />
      </div>

      <span class="chart__label">{{ index + 1 }}</span>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'chart-column',

    props: {
      columns: {
        type: Array, //[{ title: String, coveragePercentage: Number, coverageKm: number, ios3: String }]
        required: true
      }
    }
  }
</script>