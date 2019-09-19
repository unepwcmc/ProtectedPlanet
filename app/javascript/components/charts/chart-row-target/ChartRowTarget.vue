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

<!--       <polyline 
        :points="getMarkerPath(valueX)"
        :stroke-width="3"
        class="chart__marker--value"
      /> -->

      <polyline 
        :points="getMarkerPath(valueX)"
        :stroke-width="3"
        :class="`chart__stroke--${colour}`"
      />

      <polyline 
        v-if="target"
        :points="getMarkerPath(targetX, 'target')"
        :stroke-width="3"
        class="chart__marker--target"
      />

      <text
        v-if="title" 
        class="chart__title"
        x="0" 
        :y="rowHeight + 10"
      >
        {{ prettyTitle }}
      </text>
      
      <text 
        class="chart__marker-title"
        :x="valueX" 
        :y="-28"
        text-anchor="middle"
      >
        {{ prettyValue }}%
      </text>

<!--       <text 
        class="chart__marker-title"
        :x="targetX" 
        :y="-28"
        text-anchor="middle"
      >
        {{ target }}%
      </text> -->
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
      rowHeight: 18,
      svgStartX: -10,
      svgStartY: -40,
      svgWidth: 230,
      svgHeight: 74,
      chartWidth: 200,
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
    }
  }
}
</script>