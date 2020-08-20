<template>
  <div class="chart--column">
    <div 
      v-for="column, index in columns"
      :key="`column-${index}`"
      class="chart__column"
    >
      <div class="chart__bar">
        <span 
          class="chart__coverage" 
          :style="{ height: column.percentage + '%' }" 
          v-show="hasData(column)"
        />
      </div>

      <span 
        class="chart__label"
        v-show="hasData(column)"
      >
        {{ index + 1 }}
      </span>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'chart-column',

    props: {
      columns: {
        type: Array, //[{ title: String, percentage: Number, coverageKm: number, ios3: String }]
        required: true
      }
    },

    methods: {
      // there are instances when this chart 
      // should show a blank column with no data
      hasData (column) {
        return Boolean(column.percentage)
      }
    }
  }
</script>