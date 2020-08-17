<template>
  <div class="chart--line">
    <div class="chart__wrapper-ie11">
      <div class="chart__scrollable">
        <div v-if="lines" class="chart__chart" style="width:100%;">
          <svg width="100%" height="100%" :viewBox="`0 0 ${svg.width} ${svg.height}`" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid" class="chart__svg">
            <rect 
              :x="0"
              :y="0" 
              :width="svg.width" 
              :height="svg.height" 
              fill="#fff" />

            <text v-for="y, index in getAxisLabels('y')" 
              :key="`y-${index}`"
              :x="svg.paddingLeft - x.axisLabelMargin" 
              :y="y.coord "
              text-anchor="end"
              font-size="14"
              font-weight="300"
              transform="translate(0, 5)">{{ y.labelText }}{{ units }}</text>

            <text v-for="x, index in getAxisLabels('x')"  
              :key="`x-${index}`"      
              :x="x.coord" 
              :y="chartHeight + svg.paddingTop + y.axisLabelMargin" 
              font-size="14"
              font-weight="300"
              text-anchor="middle">{{ x.labelText }}</text>

            <polyline :points="getAxisLine('x')" fill="none" stroke="black" />
            <polyline :points="getAxisLine('y')" fill="none" stroke="black" />

            <chart-line-dataset 
              v-for="line, index in lines"
              :key="`yline-${index}`"
              :datapoints="normaliseDataset(line.datapoints)"
              :path="getPath(line.datapoints)"
              :colour="colours[index]"
              v-on:datapoint:mouseleave="popupHide"
              v-on:datapoint:mouseover="popupShow" 
            />

            <chart-popup
              v-show="popup.show"
              :x="popup.x" 
              :y="popup.y" 
              :text="popup.text"
            />
          </svg>
        </div>
      </div>
    </div>

    <chart-legend 
      v-if="showLegend"
      class="chart--legend--horizontal"
      :colours="legendColours"
      :rows="getLegend()"
    />
  </div>  
</template>

<script>
  import ChartLineDataset from './ChartLineDataset'
  import ChartLineTab from './ChartLineTab'
  import ChartLegend from './ChartLegend'
  import ChartPopup from './ChartPopup.vue'

  export default {
    name: 'chart-line',

    components: { 
      ChartLineDataset, 
      ChartLineTab,
      ChartLegend,
      ChartPopup
    },

    props: {
      lines: {
        type: Array, // [ id: String, datapoints: { x: Number, y: Number } ]
        required: true
      },
      units: {
        default: '%',
        type: String
      },
      showLegend: {
        default: true,
        type: Boolean
      }
    },

    data () {
      return {
        colours: [
          {
            line: '#65C9B2',
            text: '#ffffff'
          },
          {
            line: '#A54897',
            text: '#000000'
          },
          {
            line: '#5F81CB',
            text: '#000000'
          }
        ],
        popup: {
          show: false,
          text: '',
          x: 0,
          y: 0,
        },
        svg: {
          width: 740,
          height: 400,
          paddingTop: 46,
          paddingRight: 44,
          paddingBottom: 60,
          paddingLeft: 60,
        },
        x: {
          axisLabelMargin: 10, 
          incrementor: 0,
          max: 0,
          min: 0,
        },
        y: {
          axisLabelMargin: 30, 
          incrementor: 0,
          max: 0,
          min: 0,
        },
        legend: [],
        legendColours: ['#65C9B2', '#A54897', '#5F81CB'],
      }
    },

    created () {
      this.setAxisVariables()
    },

    computed: {
      chartHeight () {
        return this.svg.height - this.svg.paddingTop - this.svg.paddingBottom
      },

      chartWidth () {
        return this.svg.width - this.svg.paddingLeft - this.svg.paddingRight
      }
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
        return this.svg.paddingLeft + (((value - this.x.min) / (this.x.max - this.x.min)) * this.chartWidth)
      },

      normaliseY (value) {
        // y origin is at the top so subtract axis value from height
        // subtract the min value incase the axis doesn't start at 0
        return this.svg.paddingTop + (this.chartHeight - ((value - this.y.min) / (this.y.max - this.y.min)) * this.chartHeight)
      },

      popupHide () {
        this.popup.show = false
        this.popup.text = ''
        this.popup.x = 0
        this.popup.y = 0
      },

      popupShow (datapoint) {
        this.popup.show = true
        this.popup.text = datapoint.value 
        this.popup.x = datapoint.x
        this.popup.y = datapoint.y
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