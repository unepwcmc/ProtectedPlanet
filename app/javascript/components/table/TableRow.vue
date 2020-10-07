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
        <div class="table__cell">
          <a 
            :href="row.url"
            class="table__cell-link"
            :title="`View the statistics page for ${row.title}`"
          >
            {{ row.title }}
          </a>
        </div>

        <div
          v-for="(stat, index) in row.stats"
          class="table__cell"
        >
          <div class="table__cell-titles">
            <p class="table__cell-title">{{ stat.title }}</p>

            <tooltip 
              :on-hover="false" 
              :text="getTooltipText(stat.id)"
              class="carousel__tooltip"
            >
              <i class="icon--info-circle block"></i>
            </tooltip>
          </div>

          <chart-row-target 
            v-for="(chart, index) in stat.charts"
            :key="getVForKey('row', index)"
            :value="chart.value" 
            :target="chart.target" 
            :title="chart.title" 
            :colour="chart.colour" 
            class="table__cell-chart"
          />

          <span class="table__cell-index">{{ index + 1 }} <em class="text-thin">of</em> {{ statsCount }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import mixinId from '../../mixins/mixin-ids'
import ChartRowTarget from '../charts/chart-row-target/ChartRowTarget.vue'
import Tooltip from '../tooltip/Tooltip'

export default {
  name: 'table-row',

  components: { ChartRowTarget, Tooltip },

  mixins: [ mixinId ],

  props: {
    row: {
      type: Object, // { title: '', url: '', stats: [{ charts: [{ title: '', value: '', target: '', colour: '' }] }] }
      required: true
    },
    tooltipArray: {
      type: Array, // [ { id: String, title: String, text: String } ]
      required: true
    }
  },

  computed: {
    statsCount () {
      return this.row.stats.length
    }
  },

  methods: {
    getTooltipText (id) {
      const tooltip = this.tooltipArray.find(obj => {
        return obj.id === id
      })
      
      return tooltip !== undefined ? tooltip.text : ''
    }
  }
}
</script>