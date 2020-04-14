<template>
  <div class="chart--column-tabbed">
    chart tabs
    
    <div class="chart__chart">
      <chart-column :columns="selectedDataset" />
    </div>

    chart legend
  </div>
</template>

<script>
  import ChartColumn from './ChartColumn.vue'

  export default {
    name: 'chart-column-tabbed',

    components: { ChartColumn },

    props: {
      json: {
        required: true,
        type: Array //[{ regionTitle: String, pas: [{ title: String, coveragePercentage: Number, coverageKm: number, ios3: String }] }]
      }
    },

    data () {
      return {
        selectedDataset: this.json[0].pas
      }
    },


  }
</script>