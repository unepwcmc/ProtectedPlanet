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
          orient="auto-start-reverse"
        >
          <path d="M 0 0 L 10 5 L 0 10 z" />
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
          class="chart__arrow-line"
          :points="arrowPointsTarget" 
          fill="none"
          stroke-dasharray="6 8"
          />

        <circle
          rx="0"
          ry="0"
          r="7"
          class="chart__arrow-circle"
        />
      </g>

      <text 
        class="chart__title"
        :x="svgStartX + paddingSides" 
        :y="paddingBottom - 1"
      >
        {{ title }}
      </text>

      <text 
        class="chart__title"
        :x="-dialValueLabelArcEndX" 
        :y="-dialValueLabelArcEndY"
        text-anchor="middle"
      >
        {{ dialValue }}%
      </text>

      <text 
        class="chart__title"
        :x="-dialTargetLabelArcEndX" 
        :y="-dialTargetLabelArcEndY"
        text-anchor="middle"
      >
        {{ dialTarget }}%
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
      paddingBottom: 20,
      paddingSides: 60,
      arrowHeadSize: 5
    }
  },

  computed: {
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
    }
  },

  mounted () {
    // this.applyGradient()
  },

  methods: {
    // applyGradient () {
    //   const gp = new GradientPath({
    //     path: document.getElementById('marine'),
    //     segments: 100,
    //     samples: 3,
    //     strokeWidth: 0.5,
    //     precision: 2
    //   })

    //   gp.render({
    //     type: 'path',
    //     fill: [
    //       { color: '#4D98BF', pos: 0 },
    //       { color: '#54B7EB', pos: 1 }
    //     ],
    //     width: 10
    //   })
    // },

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
  }
}
</script>