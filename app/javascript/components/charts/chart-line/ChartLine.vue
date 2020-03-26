<template>
  <div class="chart--line">
    <div class="chart__wrapper-ie11">
      <div class="chart__scrollable">
        <div v-if="lines" class="chart__chart" style="width:100%;">
          <svg width="100%" height="100%" :viewBox="`-70 -80 ${svg.width} ${svg.height}`" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid" class="chart__svg">
            <rect 
              :x="-70"
              :y="-30" 
              :width="svg.width" 
              :height="svg.height - svg.paddingTop" 
              fill="#fff" />

            <text v-if="axis" x="-70" y="-90" font-size="18">
              <tspan v-for="t in axis.y" x="-70" :dy="24">{{ t }}</tspan>
            </text>

            <text v-for="y in yAxis" 
              :x="-x.chartPadding" 
              :y="y.coord "
              text-anchor="end"
              font-size="18"
              font-weight="300"
              transform="translate(0, 5)">{{ y.labelText }}%</text>

            <text v-for="x in xAxis" 
              :x="x.coord" 
              :y="y.chartHeight + y.chartPadding" 
              font-size="18"
              font-weight="300"
              text-anchor="middle">{{ x.labelText }}</text>

            <polyline :points="xAxisLine" fill="none" stroke="black" />
            <polyline :points="yAxisLine" fill="none" stroke="black" />

            <chart-line-dataset 
              v-for="line, index in lines"
              :index="index"
              :datapoints="normaliseDataset(line.datapoints)"
              :path="getPath(line.datapoints)"
              :middle="getPathMiddle(line.datapoints)"
              :colour="colours[index]">
            </chart-line-dataset>

<!--             <template v-if="targets">
              <chart-line-target-y v-for="target, index in targets"
                :minX="normaliseX(x.min)" 
                :maxX="normaliseX(x.max)" 
                :y="normaliseY(target.y)" 
                :title="target.title"
                :colour="targetColours[index]">
              </chart-line-target-y>
            </template>

            <template v-if="commitments">
              <chart-line-target-x v-for="commitment, index in commitments"
                :minY="normaliseY(y.min)" 
                :maxY="normaliseY(y.max)" 
                :x="normaliseX(commitment.x)"
                :line="commitment.line"
                :label="commitment.label">
              </chart-line-target-x>
            </template> -->
          </svg>
        </div>
      </div>
    </div>

    <chart-legend v-if="legend" :show-numbers="true" :rows="legend" :colours="legendColours"></chart-legend>
  </div>  
</template>

<script>
  import ChartLineDataset from './ChartLineDataset'
  import ChartLineTab from './ChartLineTab'
  // import ChartLineTargetX from './ChartLineTargetX'
  // import ChartLineTargetY from './ChartLineTargetY'
  // import ChartLegend from './ChartLegend'

  export default {
    name: 'chart-line',

    components: { 
      // ChartLineTargetX, ChartLineTargetY, 
      ChartLineDataset, 
      ChartLineTab
      // ChartLegend 
    },

    props: {
      lines: {
        type: Array, // [ { x: Number, y: Number } ]
        required: true
      },
      targets: Array,
      axis: Object,
      commitments: Array,
      legend: Array
    },

    data () {
      return {
        svg: {
          width: 1030,
          height: 650,
          paddingTop: 50
        },
        x: {
          axisMarks: 6,
          chartPadding: 24,
          chartWidth: 890,
          max: 0,
          maxNormalised: 0,
          min:0,
          minNormalised:0,
          precision: 1,
        },
        y: {
          axisMarks: 8,
          chartHeight: 500,
          chartPadding: 34,
          max: 0,
          maxNormalised: 0,
          min:0,
          minNormalised:0,
          precision: 1
        },
        colours: [
          {
            line: '#207D94',
            text: '#ffffff'
          },
          {
            line: '#6FD9F2',
            text: '#000000'
          },
          {
            line: '#86BF37',
            text: '#000000'
          }
        ],
        legendColours: ['#207D94', '#6FD9F2', '#86BF37'],
        targetColours: ['rgba(29, 125, 166, 0.4)', 'rgba(113, 163, 43, 0.4)']
      }
    },

    computed: {
      xAxis () {
        return this.getAxis('x')
      },

      yAxis () {
        return this.getAxis('y')
      },

      xAxisLine () {
        return `${this.x.minNormalised},${this.y.minNormalised} ${this.x.maxNormalised},${this.y.minNormalised}`
      },

      yAxisLine () {
        return `${this.x.minNormalised},${this.y.minNormalised} ${this.x.minNormalised},${this.y.maxNormalised}`
      }
    },

    created () {
      this.x.min = this.getMinMax('min', 'x')
      this.x.max = this.getMinMax('max', 'x')
      this.y.max = this.getMinMax('max', 'y')
      this.x.minNormalised = this.normaliseX(this.x.min)
      this.x.maxNormalised = this.normaliseX(this.x.max)
      this.y.minNormalised = this.normaliseY(this.y.min)
      this.y.maxNormalised = this.normaliseY(this.y.max)
    },

    mounted () {
      
    },

    methods: {
      getPath(dataset) {
        let path = ''
        
        dataset.forEach((point, index) => {
          let command = index == 0 ? 'M' : 'L'

          path += ` ${command} ${this.normaliseX(point.x)} ${this.normaliseY(point.y)}`
        })

        return path
      },

      getPathMiddle (dataset) {
        //used to add circle to a dataset with key used in the legend
        let middle = dataset[Math.floor(dataset.length/2)]

        return { x: this.normaliseX(middle.x), y: this.normaliseY(middle.y) }
      },

      getAxis (axis) {
        let array = [], n = this[axis].min
        const incrementor = (this[axis].max - this[axis].min)/ this[axis].axisMarks

        while( n < this[axis].max + incrementor) {
          array.push({
            coord: this[`normalise${axis.toUpperCase()}`](n),
            labelText: Math.ceil(n/this[axis].precision)*this[axis].precision
          })

          n += incrementor
        }

        return array
      },

      getMinMax(type, prop) {
        let array = []

        this.lines.forEach(line => {
          array.push(Math[type](...line.datapoints.map((t) => {
            return t[prop]
          })))
        }) 
      
        return Math.max(...array)
      },

      normaliseDataset (dataset) {
        console.log(dataset)
        const normalisedDataset = dataset.map((datapoint) => {
          return { x: this.normaliseX(datapoint.x), y: this.normaliseY(datapoint.y) }
        })
        console.log(normalisedDataset)
        return normalisedDataset
      },

      normaliseX (value) {
        // subtract the min value in case the axis doesn't start at 0
        return (((value - this.x.min) / (this.x.max - this.x.min)) * this.x.chartWidth)
      },

      normaliseY (value) {
        // y origin is at the top so subtract axis value from height
        // subtract the min value incase the axis doesn't start at 0
        return (this.y.chartHeight - ((value - this.y.min) / (this.y.max - this.y.min)) * this.y.chartHeight)
      }
    }
  }
</script>