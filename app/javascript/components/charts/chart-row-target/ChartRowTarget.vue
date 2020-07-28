<template>
  <div class="chart--row-target">
    <svg 
      xmlns="http://www.w3.org/2000/svg" 
      preserveAspectRatio="xMidYMid"
      class="chart__svg" 
      width="100%" 
      height="100%" 
      :viewBox="`${svgStartX} ${svgStartY} ${svgWidth} ${svgHeight}`"
    >
      <polyline 
        :points="getRowPath(chartWidth)" 
        :stroke-width="rowHeight" 
        class="chart__stroke--default"
      />

      <polyline 
        :points="getRowPath(valueX)"
        :stroke-width="rowHeight" 
        :class="`chart__stroke--${colour}`"
      />

      <polyline 
        :points="getMarkerPath(valueX)"
        :stroke-width="3"
        :class="`chart__stroke--${colour}`"
      />

      <polyline 
        v-if="target"
        :points="getMarkerPath(targetX, 'target')"
        class="chart__marker--target"
      />
      
      <template 
        v-if="target"
      >
        <polyline 
          :points="getLegendPath()"
          class="chart__marker--target"
        />

        <text
          v-if="title" 
          class="chart__title"
          alignment-baseline="middle"
          :x="legendWidth + 5" 
          :y="legendY"
        >
          {{ prettyTitle }}
        </text>
      </template>
      
      <text 
        class="chart__marker-title"
        :x="valueX" 
        :y="-28"
        text-anchor="middle"
      >
        {{ prettyValue }}%
      </text>
    </svg>
  </div>
</template>

<script>
export default {
  name: 'ChartRowTarget',

  props: {
    colour: {
      type: String,
      default: 'default'
    },
    target: {
      type: Number,
      default: null
    },
    title: {
      type: String,
      default: null
    },
    value: {
      type: Number,
      required: true
    }
  },

  data () {
    return {
      rowHeight: 24,
      svgStartX: -15,
      svgStartY: -42,
      svgWidth: 230,
      svgHeight: 80,
      chartWidth: 200,
      legendWidth: 10
    }
  },

  computed: {
    prettyTitle() {
      return `${this.title} target: ${this.target}%`
    },
    prettyValue() {
      return Math.round(this.value)
    },
    valueX () {
      return this.chartWidth * (this.value/100)
    },
    targetX () {
      return this.chartWidth * (this.target/100)
    },
    legendY () {
      return this.rowHeight + 5
    }
  },

  methods: {
    getMarkerPath (x, type = '') {
      const yEnd = this.rowHeight/2
      const yStart = type === 'target' ? -this.rowHeight/2 : -this.rowHeight

      return `${x} ${yStart}, ${x}, ${yEnd}`
    },

    getRowPath (x) {
      return `0,0 ${x},0`
    },

    getLegendPath () {
      return `0,${this.legendY} ${this.legendWidth},${this.legendY}`
    }
  }
}
</script>