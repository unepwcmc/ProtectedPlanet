<template>
  <div>
    <div class="sunburst">
      <div class="sunburst__info" :class="{ 'sunburst__info--active' : isActive }">
        <span class="sunburst__percentage" data-sunburst-percentage>{{ percentage }}%</span>
        <p>of downloads were used for</p>
        <span class="sunburst__type" data-sunburst-percentage>{{ type }}</span>
      </div>
    </div>
  </div>
</template>

<script>
  //import * as d3 from 'd3'

  module.exports = {
    name: 'sun-burst-chart',

    props: {
      json: {}
    },

    data () {
      return {
        width: 400,
        height: 400,
        radius: 0,
        totalSize: 0,
        svg: '',
        chart: '',
        percentage: 0,
        type: '',
        isActive: false
      }
    },

    created: function () {
      this.radius = Math.min(this.width, this.height) / 2
    },

    mounted: function () {
      console.log(d3)
      //this.renderChart()
    },

    methods: {
      renderChart: function () {
        // size variables
        var totalItems = this.json.children.length
        var color = d3.scaleSequential(d3.interpolateCool).domain([0, totalItems])
        var data = d3.hierarchy(this.json).sum(function (d) { return d.size })

        // functions
        var partition = this.partition()
        var arc = this.arc()

        // create svg elements
        this.svg = this.createSVG()
        this.chart = this.createChart()

        // data
        var nodes = partition(data).descendants()

        // build chart
        var path = this.chart.datum(data).selectAll('path')
          .data(nodes)
          .enter().append('path')
          .attr('class', 'sunburst__section')
          .attr('display', function (d) { return d.depth ? null : 'none' }) // hide inner ring
          .attr('d', function (d) { return arc(d) })
          .style('stroke', '#fff')
          .style('fill', function (d, i) { return color(i) })
          .on('mouseover', this.mouseover)
          .on('mouseleave', this.mouseLeave)

        this.totalSize = path.datum().value
      },

      createSVG: function () {
        var svg = d3.select('.sunburst')
          .append('svg')
          .attr('viewBox', '0 0 ' + this.width + ' ' + this.height)
          .attr('viewport', this.width + 'x' + this.height)
          .attr('preserveAspectRatio', 'xMidYMid')
          .attr('width', '100%')
          .attr('height', '100%')

        return svg
      },

      createChart: function (svg) {
        return this.svg.append('g').attr('transform', 'translate(' + this.width / 2 + ',' + this.height / 2 + ')')
      },

      partition: function () {
        return d3.partition().size([2 * Math.PI, this.radius * this.radius])
      },

      arc: function () {
        return d3.arc()
          .startAngle(function (d) { return d.x0 })
          .endAngle(function (d) { return d.x1 })
          .innerRadius(function (d) { return Math.sqrt(d.y0) })
          .outerRadius(function (d) { return Math.sqrt(d.y1) })
      },

      mouseover: function (d) {
        var percentage = (100 * d.value / this.totalSize).toPrecision(3)

        if (percentage < 0.1) {
          this.percentage = '< 0.1'
        } else {
          this.percentage = percentage
        }

        this.type = d.data.name

        var sequenceArray = d.ancestors().reverse()
        sequenceArray.shift() // remove root node from the array

        // fade all the segments
        d3.selectAll('path').style('opacity', 0.3)

        // highlight only those that are an ancestor of the current segment.
        this.chart.selectAll('path')
          .filter(function (node) {
            return (sequenceArray.indexOf(node) >= 0)
          })
          .style('opacity', 1)

        this.isActive = true
      },

      mouseLeave: function () {
        this.chart.selectAll('path').style('opacity', 1)
        this.isActive = false
      }
    }
  }
</script>

<style lang='scss'>
  .sunburst {
    margin: 0 auto;
    width: 50%;

    position: relative;

    &__svg {
      
    }

    &__info {
      display: none;
      position: absolute;
      top: 50%;
      left: 50%;

      transform: translate(-50%, -50%);

      &--active { display: block; }
    }

      &__percentage{
        font-size: 30px;
      }

      &__type {
        font-size: 30px;
        text-transform: capitalize;
      }
  }
</style>
