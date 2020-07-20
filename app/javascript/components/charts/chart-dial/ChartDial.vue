<template>
  <div class="chart--dial">
    <svg 
      xmlns="http://www.w3.org/2000/svg" 
      preserveAspectRatio="xMidYMid"
      class="chart__svg" 
      width="100%" 
      height="100%" 
      :viewBox="`${svgStartX} ${svgStartY} ${svgWidth} ${svgHeight}`" 
    >
      <defs>
        <marker 
          id="arrow" 
          class="chart__arrow-head"
          viewBox="0 0 10 10" 
          refX="0" 
          refY="5"
          :markerWidth="arrowHeadSize" 
          :markerHeight="arrowHeadSize"
          orient="auto"
          stroke="none"
        >
          <path d="M 0 0 L 10 5 L 0 10 z" ></path>
        </marker>
      </defs>

      <g transform="rotate(-180)">

        <path 
          v-for="(arc, index) in arcs"
          :key="getVForKey('arc', index)"
          :class="arc.class"
          :d="getArcPath(arc.percentage)"
        />

        <polyline 
          class="chart__arrow-line"
          :points="arrowPoints" 
          fill="none"
          marker-end="url(#arrow)"
          />
        
        <polyline 
          v-if="dialTarget"
          class="chart__arrow-line--target"
          :points="arrowPointsTarget" 
          fill="none"
          />

        <circle
          rx="0"
          ry="0"
          r="7"
          class="chart__arrow-circle"
        />
      </g>
      
      <template 
        v-if="dialTarget"
      >
        <polyline 
          :points="getLegendPath()"
          class="chart__arrow-line--target"
        />

        <text 
          class="chart__title"
          alignment-baseline="middle"
          :x="legendEndX + 5" 
          :y="legendY"
        >
          {{ prettyTitle }}
        </text>
      </template>

      <text 
        class="chart__title"
        :x="-dialValueLabelArcEndX" 
        :y="-dialValueLabelArcEndY"
        text-anchor="middle"
      >
        {{ prettyDialValue }}%
      </text>
    </svg>
  </div>  
</template>

<script>
// import GradientPath from 'gradient-path'
import mixinId from '../../../mixins/mixin-ids'

export default {
  name: 'ChartDial',

  mixins: [ mixinId ],

  props: {
    title: {
      type: String,
      default: null
    }, 
    dialTarget: {
      type: Number,
      default: null
    },
    dialValue: {
      type: Number,
      required: true
    },
    colour: {
      type: String,
      default: 'default'
    },
    options: {
      type: Object,
      default: () => { 
        return {
          dialThicknessPercentage: 50
        }
      }
    }
  },

  data () {
    return {
      dialDiameter: 244,
      paddingTop: 30,
      paddingBottom: 40,
      paddingSides: 60,
      arrowHeadSize: 5,
      legendWidth: 20
    }
  },

  computed: {
    prettyTitle () {
      return `${this.title} target: ${this.dialTarget}%`
    },
    prettyDialValue () {
      return Math.round(this.dialValue)
    },
    svgStartX () {
      return -this.dialDiameter/2 - this.paddingSides
    },
    svgStartY () {
      return - this.dialDiameter/2 - this.paddingTop
    },
    svgWidth () {
      return this.dialDiameter + this.paddingSides*2
    },
    svgHeight () {
      return this.dialDiameter/2 + this.paddingTop + this.paddingBottom
    },
    labelRadius () {
      return this.arcRadius + 20
    },
    arcRadius () {
      return this.dialDiameter/2
    },
    arcRadiusInner () {
      return this.arcRadius - (this.options.dialThicknessPercentage/100 * this.arcRadius)
    },
    arcs () {
      return [
        { percentage: 50, class: 'chart__arc--background' },
        { percentage: this.dialValueDegrees, class: `chart__arc--${this.colour}` }
      ]
    },
    dialValueDegrees () {
      return this.dialValue * 1/2
    },
    dialTargetDegrees () {
      return this.dialTarget * 1/2
    },
    dialValueArcEndX () {
      return this.getCoord(this.dialValueDegrees, 'x', this.arcRadius)
    },
    dialValueArcEndY () {
      return this.getCoord(this.dialValueDegrees, 'y', this.arcRadius)
    },
    dialTargetArcEndX () {
      return this.getCoord(this.dialTargetDegrees, 'x', this.arcRadius)
    },
    dialTargetArcEndY () {
      return this.getCoord(this.dialTargetDegrees, 'y', this.arcRadius)
    },
    dialValueLabelArcEndX () {
      return this.getCoord(this.dialValueDegrees, 'x', this.labelRadius)
    },
    dialValueLabelArcEndY () {
      return this.getCoord(this.dialValueDegrees, 'y', this.labelRadius)
    },
    dialTargetLabelArcEndX () {
      return this.getCoord(this.dialTargetDegrees, 'x', this.labelRadius)
    },
    dialTargetLabelArcEndY () {
      return this.getCoord(this.dialTargetDegrees, 'y', this.labelRadius)
    },
    arrowPoints () {
      const radius = this.arcRadius - this.arrowHeadSize * 3,
        outerEndX = this.getCoord(this.dialValueDegrees, 'x', radius),
        outerEndY = this.getCoord(this.dialValueDegrees, 'y', radius),
        arrowPoints = `0,0 ${outerEndX},${outerEndY}`

      return arrowPoints
    },
    arrowPointsTarget () {
      return `0,0 ${this.dialTargetArcEndX},${this.dialTargetArcEndY}`
    },
    legendStartX () {
      return this.svgStartX + this.paddingSides
    },
    legendEndX () {
      return this.legendStartX + this.legendWidth
    },
    legendY () {
      return this.paddingBottom - 14
    }
  },

  methods: {
    getArcPath(degrees) {
      const 
        start = 0,
        end = degrees,
        outerStartX = this.getCoord(start, 'x', this.arcRadius),
        outerStartY = this.getCoord(start, 'y', this.arcRadius),
        outerEndX = this.getCoord(end, 'x', this.arcRadius),
        outerEndY = this.getCoord(end, 'y', this.arcRadius),
        innerStartX = this.getCoord(end, 'x', this.arcRadiusInner),
        innerStartY = this.getCoord(end, 'y', this.arcRadiusInner),
        innerEndX = this.getCoord(start, 'x', this.arcRadiusInner),
        innerEndY = this.getCoord(start, 'y', this.arcRadiusInner)

      const d = `M ${outerStartX} ${outerStartY} 
        A ${this.arcRadius} ${this.arcRadius} 0 0 1 ${outerEndX} ${outerEndY} 
        L ${innerStartX} ${innerStartY} 
        A ${this.arcRadiusInner} ${this.arcRadiusInner} 0 0 0 ${innerEndX} ${innerEndY} 
        Z`

      return d
    },

    getCoord (degrees, coord, radius) {
      const trig = coord == 'x' ? 'cos' : 'sin'

      return radius * Math[trig]((degrees/100) * 2 * Math.PI)
    },

    getLegendPath () {
      return `${this.legendStartX},${this.legendY} ${this.legendEndX},${this.legendY}`
    }
  }
}
</script>