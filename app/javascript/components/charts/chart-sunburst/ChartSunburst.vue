<template>
  <div class="flex-row-wrap">
    <div class="flex-2-fiths">
      <div class="d3-sunburst-wrapper">
        <div class="d3-sunburst u-text-sans" :style="{ paddingTop: paddingTop }"></div>
      </div>
    </div>
    
    <div class="flex-3-fiths d3-sunburst__info-wrapper">
      <div class="d3-sunburst__info" :class="{ 'd3-sunburst__info--active' : isActive }">
          <p class="d3-sunburst__title">{{ name }}</p>
          <p v-for="item in breakdown">
            <span class="d3-sunburst__subtitle">{{ item.name }}</span>
            <span>{{ styledNumber(item.size) }}km</span>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import * as d3 from 'd3'

  export default {
    name: 'chart-sunburst',

    props: { 
      json: Object
    },

    data() {
      return {
        config: {
          width: 400,
          height: 400
        },
        radius: 0,
        totalSize: 0,
        svg: '',
        chart: '',
        name: '',
        breakdown: [],
        isActive: false,
        totalItems: 0
      }
    },

    created() {
      this.radius = Math.min(this.config.width, this.config.height) / 2
    },

    mounted() {
      this.renderChart()

      //trigger mouse enter on the first pie section so that the info panel is populated
      const firstSection = '#' + (this.json.children[0].name).replace(/\s|\./g, '-')
      d3.select(firstSection).dispatch('mouseover')
    },

    methods: {
      renderChart () {
        this.totalItems = this.json.children.length
        const color = d3.scaleSequential(d3.interpolate('#efefef', '#787878')).domain([0, this.totalItems])
        const data = d3.hierarchy(this.json).sum(function (d) { return d.size })

        // functions
        const partition = this.partition()
        const arc = this.arc()

        // create svg elements
        this.svg = this.createSVG()
        this.chart = this.createChart()

        // data
        const nodes = partition(data).descendants()

        // build chart
        const path = this.chart.datum(data).selectAll('path')
          .data(nodes)
          .enter().append('path')
          .attr('id', function(d) { return (d.data.name).replace(/\s|\./g, '-') })
          .attr('class', 'd3-sunburst__section')
          .attr('display', function (d) { return d.depth ? null : 'none' }) // hide inner ring
          .attr('d', function (d) { return arc(d) })
          .style('stroke', '#fff')
          .style('fill', function (d, i) { return color(i) })
          .on('mouseover', this.mouseover)

        this.totalSize = path.datum().value
      },

      createSVG () {
        const svg = d3.select('.d3-sunburst')
          .append('svg')
          .attr('class', 'd3-sunburst__svg')
          .attr('xmlns', 'http://www.w3.org/1999/xhtml')
          .attr('viewBox', '0 0 ' + this.config.width + ' ' + this.config.height)
          .attr('viewport', this.config.width + 'x' + this.config.height)
          .attr('preserveAspectRatio', 'xMidYMid')
          .attr('width', '100%')
          .attr('height', '100%')

        return svg
      },

      createChart (svg) {
        return this.svg.append('g').attr('transform', 'translate(' + this.config.width / 2 + ',' + this.config.height / 2 + ')')
      },

      partition () {
        return d3.partition().size([2 * Math.PI, this.radius * this.radius])
      },

      arc () {
        return d3.arc()
          .startAngle(function (d) { return d.x0 })
          .endAngle(function (d) { return d.x1 })
          .innerRadius(function (d) { return Math.sqrt(d.y0) * 3/4 })
          .outerRadius(function (d) { return Math.sqrt(d.y1) })
      },

      mouseover (d) {
        this.resetSections()

        this.name = d.data.name
        this.breakdown = d.data.breakdown

        const sequenceArray = d.ancestors().reverse()
        sequenceArray.shift() // remove root node from the array

        // highlight only those that are an ancestor of the current segment.
        this.chart.selectAll('path')
          .filter(function (node) {
            return (sequenceArray.indexOf(node) >= 0)
          })
          .style('fill', '#A1D8DE')

        this.isActive = true
      },

      resetSections () {
        const color = d3.scaleSequential(d3.interpolate('#efefef', '#787878')).domain([0, this.totalItems])
        this.chart.selectAll('path').style('fill', function (d, i) { return color(i) })
      },

      styledNumber (number) {
        return number.toLocaleString()
      }
    },
    computed: {
      paddingTop () {
        return (this.config.height / this.config.width) * 100 + '%'
      }
    }
  }
</script>