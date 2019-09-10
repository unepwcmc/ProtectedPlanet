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
        :points="getRowPath(svgWidth)" 
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
        class="chart__marker--value"
      />

      <polyline 
        :points="getMarkerPath(valueX/2)"
        :stroke-width="3"
        :class="`chart__stroke--${colour}`"
      />

      <polyline 
        v-if="target"
        :points="getMarkerPath(targetX)"
        :stroke-width="3"
        class="chart__marker--target"
      />

      <text
        v-if="title" 
        class="chart__title"
        x="0" 
        :y="rowHeight + 10"
      >
        {{ title }}
      </text>
      
      <text 
        class="chart__marker-title"
        :x="valueX/2" 
        :y="-28"
        text-anchor="middle"
      >
        {{ prettyValue }}%
      </text>

      <text 
        class="chart__marker-title"
        :x="targetX" 
        :y="-28"
        text-anchor="middle"
      >
        {{ target }}%
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
      rowHeight: 18,
      svgStartX: 0,
      svgStartY: -40,
      svgWidth: 222,
      svgHeight: 70,
      valueX: 0,
      targetX: 0,
    }
  },

  computed: {
    prettyValue() {
      return Math.trunc(this.value)
    }
  },

  mounted () {
    this.valueX = this.svgWidth * (this.value/100)
    this.targetX = this.svgWidth * (this.target/100)
  },

  methods: {
    getMarkerPath (x) {
      const yStart = -this.rowHeight,
        yEnd = this.rowHeight/2

      return `${x} ${yStart}, ${x}, ${yEnd}`
    },

    getRowPath (x) {
      return `0,0 ${x},0`
    }
  }
}
</script>