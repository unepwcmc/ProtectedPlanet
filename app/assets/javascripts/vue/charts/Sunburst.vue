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
  module.exports = {
    name: 'sunburst',

    props: { },

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
        isActive: false,
        json: {
          "name": "protected areas",
          "children": [
            {
              "name": "Cook Islands",
              "size": 1900000
            },
            {
              "name": "Grenada",
              "size": 1154
            },
            {
              "name": "Indonesia",
              "size": 28547
            },
            {
              "name": "Marshall Islands",
              "size": 305.5
            },
            {
              "name": "IDN/TLS",
              "size": 6450
            },
            {
              "name": "Colombia",
              "size": 15000
            },
            {
              "name": "Chile",
              "size": 150000
            },
            {
              "name": "China",
              "size": 10432
            },
            {
              "name": "Germany (CCAMLR)",
              "size": 1800000
            },
            {
              "name": "19 countries",
              "size": 3700000
            }
          ]
        }
      }
    },

    created() {
      this.radius = Math.min(this.width, this.height) / 2
    },

    mounted() {
      this.renderChart()
    },

    methods: {
      renderChart() {
        // size variables
        
        var totalItems = this.json.children.length
        var color = d3.scaleSequential(d3.interpolate('#efefef', '#787878')).domain([0, totalItems])
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

      createSVG() {
        var svg = d3.select('.sunburst')
          .append('svg')
          .attr('viewBox', '0 0 ' + this.width + ' ' + this.height)
          .attr('viewport', this.width + 'x' + this.height)
          .attr('preserveAspectRatio', 'xMidYMid')
          .attr('width', '100%')
          .attr('height', '100%')

        return svg
      },

      createChart(svg) {
        return this.svg.append('g').attr('transform', 'translate(' + this.width / 2 + ',' + this.height / 2 + ')')
      },

      partition() {
        return d3.partition().size([2 * Math.PI, this.radius * this.radius])
      },

      arc() {
        return d3.arc()
          .startAngle(function (d) { return d.x0 })
          .endAngle(function (d) { return d.x1 })
          .innerRadius(function (d) { return Math.sqrt(d.y0) * 3/4 })
          .outerRadius(function (d) { return Math.sqrt(d.y1) })
      },

      mouseover(d) {
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
        //d3.selectAll('path').style('opacity', 0.3)

        // highlight only those that are an ancestor of the current segment.
        this.chart.selectAll('path')
          .filter(function (node) {
            return (sequenceArray.indexOf(node) >= 0)
          })
          .style('fill', '#A1D8DE')

        this.isActive = true
      },

      mouseLeave() {
        var totalItems = this.json.children.length
        var color = d3.scaleSequential(d3.interpolate('#efefef', '#898989')).domain([0, totalItems])
        //this.chart.selectAll('path').style('opacity', 1)
        this.chart.selectAll('path').style('fill', function (d, i) { return color(i) })
        this.isActive = false
      }
    }
  }
</script>