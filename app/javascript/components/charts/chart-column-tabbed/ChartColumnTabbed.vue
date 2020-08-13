<template>
  <div class="chart--column-tabbed">

    <tabs-fake
      class="chart__tabs tabs--underlined"
      :children="tabs"
      v-on:click:tab="changeTab"
    />

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
  import TabsFake from '../../tabs/TabsFake.vue'

  export default {
    name: 'chart-column-tabbed',

    components: { ChartColumn, ChartLegend, TabsFake },

    props: {
      json: {
        required: true,
        type: Array //[{ regionTitle: String, countries: [{ title: String, percentage: Number, coverageKm: number, ios3: String }] }]
      }
    },

    data () {
      return {
        selectedDatasetIndex: 0,
      }
    },

    computed: {
      legend () {
        // there are instances when this chart 
        // should show a blank column with no data
        // but it should not appear in the legend
        return this.selectedDataset
          .filter(column => Boolean(column.percentage))
          .map(column => {
            return {
              title: `${column.title} (${column.iso3})`,
              subtitle: `${column.percentage}%, (${column.km}km<sup>2</sup>)`
            }
          })
      },

      selectedDataset () {
        return this.json[this.selectedDatasetIndex].countries
      },

      tabs () {
        return this.json.map((region, index) => {
          return {
            id: index.toString(),
            selectedId: this.selectedDatasetIndex,
            title: region.regionTitle
          }
        })
      }
    },

    methods: {
      changeTab (selected) {
        this.selectedDatasetIndex = selected
      }
    }
  }
</script>
