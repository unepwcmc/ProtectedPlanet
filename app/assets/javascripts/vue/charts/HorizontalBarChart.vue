<template>
  <div :id="svgId" class="d3-horizontal-bar-chart sm-bar-chart" :style="{ paddingTop: paddingTop }"></div>
</template>

<script>
  module.exports = {
    name: "horizontal-bar-chart",

    props: {
      id: String,
      json: Array,
      xAxisMax: Number
    },

    data: function() {
      return {
        config: {
          width: 555,
          height: 240,
          marginLeft: 140, 
          marginRight: 20,
          marginBottom: 30,
          unit: '%'
        },
        chartWidth: 0,
        chartHeight: 0,
        svgId: 'd3-horizontal-bar-chart'
      }
    },

    created: function() {
      this.chartWidth = this.config.width - this.config.marginLeft - this.config.marginRight
      this.chartHeight = this.config.height - this.config.marginBottom
      this.svgId = 'd3-' + this.id
    },

    mounted: function() {
      this.renderChart()
    },

    methods: {
      renderChart: function () {
        var data = this.json

        var svg = this.createSVG()

        var chart = svg.append('g')
          .attr('transform', 'translate(' + this.config.marginLeft + ', 0)')

        var x = d3.scaleLinear().range([0, this.chartWidth])
        var y = d3.scaleBand().range([this.chartHeight, 0])

        // the largest bar should appear at the top
        data.sort(function(a, b) { return a.value - b.value; });

        // if a max value has been passed through as a prop, use this to create the x axis domain
        if(this.xAxisMax){
          x.domain([0, this.xAxisMax])
        } else {
          x.domain([0, d3.max(data, function (d) { return d.value })])
        }

        y.domain(data.map(function (d) { return d.name })).padding(.5)

        // add chart background
        chart.append('rect')
          .attr('width', this.chartWidth)
          .attr('height', this.chartHeight)
          .attr('class', 'background')

        // add x axis
        chart.append('g')
          .attr('class', 'xaxis')
          .attr('transform', 'translate(0, ' + this.chartHeight + ')')
          .call(
            d3.axisBottom(x)
              .ticks(6)
              .tickSize(0)
              .tickPadding(10)
          )

        // add y axis
        chart.append('g')
          .attr('class', 'yaxis')
          .call(d3.axisLeft(y).tickSize(0).tickPadding(10))
          .selectAll('.tick text')
          .call(this.wrap, this.config.marginLeft)

        // add gridlines
        chart.append('g')
          .attr('class', 'gridlines')
          .attr('transform', 'translate(0, ' + this.chartHeight + ')')
          .call(d3.axisBottom(x).ticks(6).tickSize(-this.chartHeight, 0, 0).tickFormat(''))

        // add bars
        var bar = chart.selectAll('.bar')
          .data(data)
          .enter().append('g')
          .attr('transform', function (d) { return 'translate(0, ' + y(d.name) + ')' })

          bar.append('rect')
            .attr('class', 'bar')
            .attr('x', 0)
            .attr('y', 0)
            .attr('height', y.bandwidth())
            .attr('width', function (d) { return x(d.value) })
          
          var self = this

          // add bar labels
          bar.append('text')
            .attr('class', 'bar-label')
            .attr('transform', function (d) { 
              return 'translate(' + (x(d.value) - 10) + ',' + ((y.bandwidth()/2) + 4) + ')' 
            })
            .attr('text-anchor', 'end')
            .text(function(d) { return self.styledNumber(d.value) + self.config.unit })
      },

      createSVG: function () {
        var svg = d3.select('#' + this.svgId)
          .append('svg')
          .attr('class', 'd3-horizontal-bar-chart__svg')
          .attr('xmlns', 'http://www.w3.org/1999/xhtml')
          .attr('viewBox', '0 0 ' + this.config.width + ' ' + this.config.height)
          .attr('viewport', this.config.width + 'x' + this.config.height)
          .attr('preserveAspectRatio', 'xMidYMid')
          .attr('width', '100%')
          .attr('height', '100%')

        return svg
      },

      styledNumber: function (number) {
        return number.toLocaleString()
      },

      wrap: function (text, width) {
        text.each(function () {
          var text = d3.select(this)
          var words = text.text().split(/\s+/).reverse()
          var line = []
          var lineNumber = 0
          var lineHeight = 1.1
          var x = text.attr('x')
          var dy = 0

          var tspan = text.text(null)
            .append('tspan')
            .attr('x', x)
            .attr('y', 0)
            .attr('dy', dy + 'em')

          while (word = words.pop()) {
            line.push(word)
            tspan.text(line.join(' '))

            if(tspan.node().getComputedTextLength() > width) {
              line.pop()
              tspan.text(line.join(' '))

              line = [word]
              tspan = text.append('tspan')
                .attr('x', x)
                .attr('y', 0)
                .attr('dy', ++lineNumber * lineHeight + dy + 'em')
                .text(word)
            }
          }
        })        
      }
    },

    computed: {
      paddingTop: function () {
        return (this.config.height / this.config.width) * 100 + '%'
      }
    }
  }
</script>
