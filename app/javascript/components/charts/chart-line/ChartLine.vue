<template>
  <div class="v-interactive-multiline sm-multiline">
    <div class="v-interactive-multiline__tabs">

      <chart-line-tab v-for="name, key in datasetNames" 
        :key="key"
        :name="name"
        :selected="selectedTab"
        class="v-interactive-multiline__tab-title" 
        v-on:tabClicked="draw(name)"
      ></chart-line-tab>

    </div>

    <div class="d3-svg v-interactive-multiline__chart"  :style="{ paddingTop: paddingTop }"></div>

  </div>
</template>

<script>
  import ScrollMagic from 'scrollmagic'
  import * as d3 from 'd3'

  import ChartLineTab from './ChartLineTab'

  export default {
    name: 'chart-line',

    components: { ChartLineTab },

    props: {
      json: { required: true }
    },

    data () {
      return {
        config: {
          width: 860,
          height: 370,
          margin: 80,
          datapointRadius: 4,
          yAxisMaxValue: 20,
          xAxisNumberOfTicks: 8
        },
        svg:'',
        chart: '',
        chartWidth: 0,
        chartHeight: 0,
        datasetNames: [],
        scaleX: '',
        scaleY: '',
        selectedTab: ''
      }
    },

    created () {
      this.chartWidth = this.config.width - this.config.margin
      this.chartHeight = this.config.height - this.config.margin
    },

    mounted () {
      this.createButtons()
      this.renderChart()

      // animate in the first series so that chart isn't  empty
      const multilineController = new ScrollMagic.Controller()

      new ScrollMagic.Scene({ triggerElement: '.sm-multiline', reverse: false })
        .on('start', () => {
          this.draw(this.datasetNames[0])
        })
        .addTo(multilineController)
    },

    methods: {
      createButtons (){
        this.json.forEach((dataset) => {
          this.datasetNames.push(dataset.id)
        })
      },

      renderChart (){
        const data = this.json
        const parseTime = d3.timeParse("%Y")

        // set the ranges
        const x = d3.scaleTime().range([0, this.chartWidth])
        const y = d3.scaleLinear().range([this.chartHeight, 0])

        // define the line
        const line = d3.line()
          .x(function(d) { return x(parseTime(d.year)) })
          .y(function(d) { return y(d.percent) })

        // Scale the range of the data
        x.domain([
          d3.min(data, function(c) { 
            return d3.min(c.dataset, function(d){ return parseTime(d.year) })
          }),
          d3.max(data, function(c) { 
            return d3.max(c.dataset, function(d){ return parseTime(d.year) })
          })
        ])

        y.domain([0, this.config.yAxisMaxValue])

        // create svg
        this.svg = this.createSVG()

        // create chart group
        this.chart = this.svg.append('g')
          .attr('class', 'chart')
          .attr('width', this.chartWidth)
          .attr('height', this.chartHeight)
          .attr('transform', 'translate(' + this.config.margin/2 + ',' + this.config.margin/2 + ')')

        // add y gridlines
        this.chart.append('g')
          .attr('class', 'v-interactive-multiline__gridlines')
          .call(d3.axisLeft(y).tickSize(-this.chartWidth, 0, 0).tickFormat(''))

        // add x axis
        this.chart.append('g')
          .attr('class', 'v-interactive-multiline__axis')
          .attr('transform', 'translate(0,' + this.chartHeight + ')')
          .call(d3.axisBottom(x).ticks(this.config.xAxisNumberOfTicks))

        // add y axis
        this.chart.append('g')
          .attr('class', 'v-interactive-multiline__axis')
          .call(d3.axisLeft(y).tickFormat(function(d){ return d + '%'}))

        this.scaleX = x
        this.scaleY = y

        // add data path
        const dataset = this.chart
          .selectAll('.dataset')
          .data(data)
          .enter().append('path')
          .attr('class', 'v-interactive-multiline__line')
          .attr('data-name', function(d) { return d.id })
          .attr('d', function(d) { return line(d.dataset) })
          .attr('stroke', 'black')
          .attr('fill', 'none')

        // add a group for each set of datapoints
        const datapointWrappers = this.chart
          .selectAll('.datapoint-wrappers')
          .data(data)
          .enter()
          .append('g')
          .attr('class', 'v-interactive-multiline__datapoints')
          .attr('data-datapoints', function(d) { return d.id })

        // add a group for each data point
        const datapoints = datapointWrappers.selectAll('.datapoints')
          .data(function(d){ return d.dataset })
          .enter()
          .append('g')
          .attr('class', 'datapoint-group')

        // add the tooltip
        datapoints.append('text')
          .text(function (d) { return d.percent + '%' })
          .attr('data-tooltip', function(d) { 
            return d3.select(this.parentNode.parentNode).datum().id + '-' + d.year
          })
          .attr('class', 'v-interactive-multiline__tooltip')
          .attr('transform', function (d) { 
            return 'translate(' + x(parseTime(d.year)) + ', ' + (y(d.percent) - 20) + ')' 
          })

        // add the circle datapoint
        datapoints.append('circle')
          .attr('cx', (d) => { return this.scaleX(parseTime(d.year)) })
          .attr('cy', (d) => { return this.scaleY(d.percent) })
          .attr('r', this.config.datapointRadius)
          .attr('class', 'v-interactive-multiline__datapoint')
          .on('mouseenter', function (d) {
            const id = d3.select(this.parentNode.parentNode).datum().id + '-' + d.year

            $('[data-tooltip="' + id + '"]')
              .attr('class', 'v-interactive-multiline__tooltip v-interactive-multiline__tooltip-active')
            }
          )
          .on('mouseleave', function (d) {
            const id = d3.select(this.parentNode.parentNode).datum().id + '-' + d.year

            $('[data-tooltip="' + id + '"]')
              .attr('class', 'v-interactive-multiline__tooltip')
            }
          )
      },

      createSVG (){
        const svg = d3.select('.d3-svg')
          .append('svg')
          .attr('class', 'v-interactive-multiline__svg')
          .attr('xmlns', 'http://www.w3.org/1999/xhtml')
          .attr('viewBox', '0 0 ' + this.config.width + ' ' + this.config.height)
          .attr('viewport', this.config.width + 'x' + this.config.height)
          .attr('preserveAspectRatio', 'xMidYMid')
          .attr('width', '100%')
          .attr('height', '100%')

        return svg
      },

      draw (name){
        this.selectedTab = name

        const lineClass = 'v-interactive-multiline__line',
          activeLineClasses = lineClass + ' v-interactive-multiline__line-active',
          datapointClass = 'v-interactive-multiline__datapoints',
          activeDatapointClasses = datapointClass + ' v-interactive-multiline__datapoints-active'

        $('.' + lineClass).attr('class', lineClass)
        $('[data-name="' + name + '"]').attr('class', activeLineClasses)

        $('.' + datapointClass).attr('class', datapointClass)
        $('[data-datapoints="' + name + '"]').attr('class', activeDatapointClasses)
      }
    },

    computed: {
      paddingTop: function () {
        return (this.config.height / this.config.width) * 100 + '%'
      }
    }
  }
</script>