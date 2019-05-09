<template>
  <div :id="svgId" class="d3-horizontal-bar-chart sm-bar-chart" :style="{ paddingTop: paddingTop }"></div>
</template>

<script>
  import ScrollMagic from 'scrollmagic'
  import * as d3 from 'd3'

  export default {
    name: "horizontal-bar-chart",

    props: {
      id: String,
      json: Array,
      xAxisMax: Number
    },

    data () {
      return {
        config: {
          width: 555,
          height: 240,
          marginLeft: 140, 
          marginRight: 20,
          marginBottom: 30,
          unit: '%',
          yTickPadding: 10
        },
        chartWidth: 0,
        chartHeight: 0,
        svgId: 'd3-horizontal-bar-chart'
      }
    },

    created () {
      this.chartWidth = this.config.width - this.config.marginLeft - this.config.marginRight
      this.chartHeight = this.config.height - this.config.marginBottom
      this.svgId = 'd3-' + this.id
    },

    mounted () {
      this.renderChart()
      this.scrollMagicHandlers()
    },

    methods: {
      scrollMagicHandlers () {
        const marineScrollMagic = new ScrollMagic.Controller()
        
        new ScrollMagic.Scene({ triggerElement: '.sm-bar-chart', reverse: false })
          .setClassToggle('.sm-bar-chart', 'd3-horizontal-bar-chart-animate')
          .addTo(marineScrollMagic)
      },

      renderChart () {
        const data = this.json

        const svg = this.createSVG()

        const chart = svg.append('g')
          .attr('transform', 'translate(' + this.config.marginLeft + ', 0)')

        const x = d3.scaleLinear().range([0, this.chartWidth])
        const y = d3.scaleBand().range([this.chartHeight, 0])

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
          .call(d3.axisLeft(y).tickSize(0).tickPadding(this.config.yTickPadding))
          .selectAll('.tick text')
          .call(this.wrap, this.config.marginLeft - this.config.yTickPadding)

        // add gridlines
        chart.append('g')
          .attr('class', 'gridlines')
          .attr('transform', 'translate(0, ' + this.chartHeight + ')')
          .call(d3.axisBottom(x).ticks(6).tickSize(-this.chartHeight, 0, 0).tickFormat(''))

        // add bars
        const bar = chart.selectAll('.bar')
          .data(data)
          .enter().append('g')
          .attr('transform', function (d) { return 'translate(0, ' + y(d.name) + ')' })

          bar.append('rect')
            .attr('class', 'bar')
            .attr('x', 0)
            .attr('y', 0)
            .attr('height', y.bandwidth())
            .attr('width', function (d) { return x(d.value) })
          
          // add bar labels
          bar.append('text')
            .attr('class', (d) => {
              //if bar is less than 10% width then add additional class

              if(x(d.value)/this.xAxisMax < 0.1){
                return 'bar-label bar-label--dark'
              } else {
                return 'bar-label'
              }
            })
            .attr('transform', (d) => { 
              var start = 0

              //if bar is less than 10% width then show label at the end
              if(x(d.value)/this.xAxisMax < 0.1){
                start = x(d.value) + 10
              } else {
                start = x(d.value) - 10
              }

              return 'translate(' + start + ',' + ((y.bandwidth()/2) + 4) + ')' 
            })
            .attr('text-anchor', (d) => {
              //if bar is less than 10% width then show label at the end
              
              if(x(d.value)/this.xAxisMax < 0.1){
                return 'start'
              } else {
                return 'end'
              }
            })
            .text((d) => { return this.styledNumber(d.value) + this.config.unit })
      },

      createSVG () {
        const svg = d3.select('#' + this.svgId)
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

      styledNumber (number) {
        return number.toLocaleString()
      },

      wrap (text, width) {
        text.each(function () {
          const text = d3.select(this),
            words = text.text().split(/\s+/).reverse(),
            lineHeight = 1.1,
            x = text.attr('x'),
            dy = 0

          let word = '',
            line = [],
            lineNumber = 0,
            tspan = text.text(null)
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
      paddingTop () {
        return (this.config.height / this.config.width) * 100 + '%'
      }
    }
  }
</script>
