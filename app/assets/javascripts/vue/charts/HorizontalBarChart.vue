<template>
  <div>
    <div class="d3-horizontal-bar-chart"></div>
  </div>
</template>

<script>
  module.exports = {
    name: "horizontal-bar-chart",

    props: {
      json: Array
    },

    data () {
      return {
        config: {
          width: 555,
          height: 240,
          marginLeft: 140, 
          marginBottom: 30
        },
        chartWidth: 0,
        chartHeight: 0,
      }
    },

    created () {
      this.chartWidth = this.config.width - this.config.marginLeft
      this.chartHeight = this.config.height - this.config.marginBottom
    },

    mounted () {
      this.renderChart()
    },

    methods: {
      renderChart () {
        var data = this.json

        console.log(data)

        var svg = this.createSVG()

        var chart = svg.append('g')
          .attr('transform', 'translate(' + this.config.marginLeft + ', 0)')

        var x = d3.scaleLinear().range([0, this.chartWidth])
        var y = d3.scaleBand().range([this.chartHeight, 0])

        x.domain([0, d3.max(data, function (d) { return d.value })])
        y.domain(data.map(function (d) { return d.name })).padding(.5)

        // add x axis
        chart.append('g')
          .attr('transform', 'translate(0, ' + this.chartHeight + ')')
          .call(d3.axisBottom(x).tickFormat(function (d) { return d/100   }))

        // add y axis
        chart.append('g')
          .call(d3.axisLeft(y))

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
          
          bar.append('text')
            .attr('class', 'bar-label')
            .attr('transform', function (d) { return 'translate(' + x(d.value) + ',' + y.bandwidth()/2 + ')' })
            .attr('text-anchor', 'end')
            .text(function (d) { return d.value + 'km'})
      },

      createSVG () {
        var svg = d3.select('.d3-horizontal-bar-chart')
          .append('svg')
          .attr('viewBox', '0 0 ' + this.config.width + ' ' + this.config.height)
          .attr('viewport', this.config.width + 'x' + this.config.height)
          .attr('preserveAspectRatio', 'xMidYMid')
          .attr('width', '100%')
          .attr('height', '100%')

        return svg
      },
    }
  }
</script>
