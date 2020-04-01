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

            <text v-for="y in getAxisLabels('y')" 
              :x="-x.chartPadding" 
              :y="y.coord "
              text-anchor="end"
              font-size="18"
              font-weight="300"
              transform="translate(0, 5)">{{ y.labelText }}%</text>

            <text v-for="x in getAxisLabels('x')"             
              :x="x.coord" 
              :y="y.chartHeight + y.chartPadding" 
              font-size="18"
              font-weight="300"
              text-anchor="middle">{{ x.labelText }}</text>

            <polyline :points="getAxisLine('x')" fill="none" stroke="black" />
            <polyline :points="getAxisLine('y')" fill="none" stroke="black" />

            <chart-line-dataset 
              v-for="line, index in lines"
              :index="index"
              :datapoints="normaliseDataset(line.datapoints)"
              :path="getPath(line.datapoints)"
              :middle="getPathMiddle(line.datapoints)"
              :colour="colours[index]">
            </chart-line-dataset>
          </svg>
        </div>
      </div>
    </div>

    <chart-legend 
      v-if="showLegend"
      :colours="legendColours"
      :rows="getLegend()"
    />
  </div>  
</template>

<script>
  import ChartLineDataset from './ChartLineDataset'
  import ChartLineTab from './ChartLineTab'
  import ChartLegend from './ChartLegend'

  export default {
    name: 'chart-line',

    components: { 
      ChartLineDataset, 
      ChartLineTab,
      ChartLegend 
    },

    props: {
      lines: {
        type: Array, // [ id: String, datapoints: { x: Number, y: Number } ]
        required: true
      },
      axis: Object,
      showLegend: {
        default: true,
        type: Boolean
      }
    },

    data () {
      return {
        svg: {
          width: 1030,
          height: 650,
          paddingTop: 50
        },
        x: {
          chartPadding: 24,
          chartWidth: 890,
          incrementor: 0,
          precision: 1,
          max: 0,
          min: 0
        },
        y: {
          chartHeight: 500,
          chartPadding: 34,
          incrementor: 0,
          precision: 1,
          max: 0,
          min: 0
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
        legend: [],
        legendColours: ['#207D94', '#6FD9F2', '#86BF37'],
        // targetColours: ['rgba(29, 125, 166, 0.4)', 'rgba(113, 163, 43, 0.4)']
      }
    },

    created () {
      this.setAxisVariables()
    },

    methods: {
      getLegend (){
        const legend = this.lines.map((dataset) => {
          return { title: dataset.id }
        })

        return legend
      },

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

      getAxisLabels (axis) {
        const incrementor = this[axis].incrementor,
          min = this[axis].min,
          max = this[axis].max

        let n = min, array = []
          
        while( n <= max) {
          array.push({
            coord: this[`normalise${axis.toUpperCase()}`](n),
            labelText: n
          })

          n += incrementor
        }

        return array
      },

      getAxisLine (axis) {
        const minX = this.normaliseX(this.x.min),
          minY = this.normaliseY(this.y.min),
          maxX = this.normaliseX(this.x.max),
          maxY = this.normaliseY(this.y.max)

        const axisLine = axis == 'x' ? `${minX},${minY} ${maxX},${minY}` : `${minX},${minY} ${minX},${maxY}`
        
        return axisLine
      },

      getMinMax(type, prop) {
        let array = []
        const rounding = type == 'min' ? 'floor' : 'ceil'

        this.lines.forEach(line => {
          array.push(Math[type](...line.datapoints.map((t) => {
            return Math[rounding](t[prop])
          })))
        }) 
      
        return Math[type](...array)
      },

      normaliseDataset (dataset) {
        const normalisedDataset = dataset.map((datapoint) => {
          return { 
            value: datapoint.y + '%',
            x: this.normaliseX(datapoint.x),
            y: this.normaliseY(datapoint.y)
          }
        })
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
      },

      setAxisVariables () {
        const totalDatapoints = this.lines[0].datapoints.length,
          evenTotal = totalDatapoints % 2 == 0,
          xMin = this.getMinMax('min', 'x'),
          xMax = this.getMinMax('max', 'x'),
          yMin = this.getMinMax('min', 'y'),
          yMax = this.getMinMax('max', 'y'),
          axisMarks = evenTotal ? totalDatapoints/2 : (totalDatapoints - 1)/2
          
        this.x.incrementor = evenTotal ? (xMax - xMin)/(axisMarks - .5) : (xMax - xMin)/(axisMarks)
        this.y.incrementor = evenTotal ? (yMax - yMin)/(axisMarks - .5) : (yMax - yMin)/(axisMarks)
        this.x.min = xMin
        this.y.min = yMin
        this.x.max = xMin + (this.x.incrementor * axisMarks)
        this.y.max = yMin + (this.y.incrementor * axisMarks)
      }
    }
  }
</script>