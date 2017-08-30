<template>
  <div class="v-interactive-multiline sm-multiline">
    <div class="v-interactive-multiline__tabs">

      <tab-title v-for="name, key in datasetNames" 
        :key="key"
        :name="name"
        :selected="selectedTab"
        class="v-interactive-multiline__tab-title" 
        v-on:tabClicked="draw(name)"
      ></tab-title>

    </div>

    <div class="d3-svg v-interactive-multiline__chart"></div>

  </div>
</template>

<script>
  // require 

  module.exports = {
    name: 'interactive-multiline',

    components: {
      'tab-title': VComponents['vue/charts/interactive_multiline/TabTitle']
    },

    props: {
      json: { required: true }
    },

    data: function() {
      return {
        config: {
          width: 860,
          height: 370,
          margin: 80,
          datapointRadius: 4,
          yAxisMaxValue: 50,
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

    created: function() {
      this.chartWidth = this.config.width - this.config.margin
      this.chartHeight = this.config.height - this.config.margin
    },

    mounted: function() {
      this.createButtons()
      this.renderChart()

      // animate in the first series so that chart isn't  empty
      multilineController = new ScrollMagic.Controller()
      var self = this

      new ScrollMagic.Scene({ triggerElement: '.sm-multiline', reverse: false })
        .on('start', function () {
          self.draw(self.datasetNames[0])
        })
        .addTo(multilineController)
    },

    methods: {
      createButtons: function(){
        var self = this

        this.json.forEach(function (dataset) {
          self.datasetNames.push(dataset.id)
        })
      },

      renderChart: function(){
        var data = this.json
        var parseTime = d3.timeParse("%Y")

        // set the ranges
        var x = d3.scaleTime().range([0, this.chartWidth])
        var y = d3.scaleLinear().range([this.chartHeight, 0])

        // define the line
        var line = d3.line()
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

        //add target line
        this.chart.append('g')
        .attr('class', 'v-interactive-multiline__target')
          .attr('transform', 'translate(0,' + this.chartHeight + ')')
          .call(
            d3.axisBottom(x)
              .tickSize(-this.chartHeight, 0, 0)
              .tickValues([parseTime(2017)])
          )

        this.scaleX = x
        this.scaleY = y

        // add data path
        var dataset = this.chart
          .selectAll('.dataset')
          .data(data)
          .enter().append('path')
          .attr('class', 'v-interactive-multiline__line')
          .attr('data-name', function(d) { return d.id })
          .attr('d', function(d) { return line(d.dataset) })
          .attr('stroke', 'black')
          .attr('fill', 'none')

        // add a group for each set of datapoints
        var datapointWrappers = this.chart
          .selectAll('.datapoint-wrappers')
          .data(data)
          .enter()
          .append('g')
          .attr('class', 'v-interactive-multiline__datapoints')
          .attr('data-datapoints', function(d) { return d.id })

        // add a group for each data point
        var datapoints = datapointWrappers.selectAll('.datapoints')
          .data(function(d){ return d.dataset })
          .enter()
          .append('g')
          .attr('class', 'datapoint-group')

        // add the tooltip
        datapoints.append('text')
          .text(function(d){ return d.percent })
          .attr('data-tooltip', function(d) { 
            return d3.select(this.parentNode.parentNode).datum().id + '-' + d.year
          })
          .attr('class', 'v-interactive-multiline__tooltip')
          .attr('transform', function (d) { 
            return 'translate(' + x(parseTime(d.year)) + ', ' + (y(d.percent) - 20) + ')' 
          })

        var self = this

        // add the circle datapoint
        datapoints.append('circle')
          .attr('cx', function (d) { return self.scaleX(parseTime(d.year)) })
          .attr('cy', function (d) { return self.scaleY(d.percent) })
          .attr('r', this.config.datapointRadius)
          .attr('class', 'v-interactive-multiline__datapoint')
          .on('mouseenter', function(d) {
            var id = d3.select(this.parentNode.parentNode).datum().id + '-' + d.year

            $('[data-tooltip="' + id + '"]')
              .addClass('v-interactive-multiline__tooltip-active')
            }
          )
          .on('mouseleave', function(d) {
            var id = d3.select(this.parentNode.parentNode).datum().id + '-' + d.year

            $('[data-tooltip="' + id + '"]')
              .removeClass('v-interactive-multiline__tooltip-active')
            }
          )
      },

      createSVG: function(){
        var svg = d3.select('.d3-svg')
          .append('svg')
          .attr('viewBox', '0 0 ' + this.config.width + ' ' + this.config.height)
          .attr('viewport', this.config.width + 'x' + this.config.height)
          .attr('preserveAspectRatio', 'xMidYMid')
          .attr('width', '100%')
          .attr('height', '100%')

        return svg
      },

      draw: function(name){
        this.selectedTab = name

        var lineClass = 'v-interactive-multiline__line-active'
        var datapointClass = 'v-interactive-multiline__datapoints-active'

        $('.v-interactive-multiline__line').removeClass(lineClass)
        $('[data-name="' + name + '"]').addClass(lineClass)

        $('.v-interactive-multiline__datapoints').removeClass(datapointClass)
        $('[data-datapoints="' + name + '"]').addClass(datapointClass)
      }
    }
  }
</script>