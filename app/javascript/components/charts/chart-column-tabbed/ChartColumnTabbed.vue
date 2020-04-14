<template>
  <div class="chart--column-tabbed">
    chart tabs
    
    <div class="chart__tab-target">
      <chart-column 
        class="chart__chart"
        :columns="selectedDataset" 
      />

      <chart-legend 
        class="chart__legend chart--legend--vertical"
        :showIcons="false"
        :showNumbers="true" 
        :rows="legend" 
      />
    </div>
  </div>
</template>

<script>
  import ChartColumn from './ChartColumn.vue'
  import ChartLegend from '../chart-line/ChartLegend.vue'

  export default {
    name: 'chart-column-tabbed',

    components: { ChartColumn, ChartLegend },

    props: {
      json: {
        required: true,
        type: Array //[{ regionTitle: String, pas: [{ title: String, coveragePercentage: Number, coverageKm: number, ios3: String }] }]
      }
    },

    data () {
      return {
        selectedDatasetIndex: 0
      }
    },

    computed: {
      legend () {
        return this.selectedDataset.map((column) => {
          return { 
            title: column.title,
            subtitle: `${column.percentage}%, (${column.km}km<sup>2</sup>)`
          }
        })
      },

      selectedDataset () {
        return this.json[this.selectedDatasetIndex].pas
      }
    }
  }
</script>