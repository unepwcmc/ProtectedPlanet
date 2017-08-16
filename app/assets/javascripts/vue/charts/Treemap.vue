<template>
  <div class="treemap"></div>
</template>

<script>
  module.exports = {
    name: 'treemap',

    props: {
      interactive: Boolean,
      json: { required: true }
    },

    data() {
      return {
        config: {
          width: 700,
          height: 550
        },
        orderedData: 0,
      }
    },

    mounted() {
      this.renderChart()

      //trigger mouse enter on the first cell so that the info panel is populated
      var firstCountry = '#' + (this.orderedData.children[0].data.id).replace(/\s|\./g, '-')
      d3.select(firstCountry).dispatch('mouseenter')
    },

    methods: {
      renderChart: function(){
        var svg = this.createSVG()

        //data
        var treemap = d3.treemap()
          .tile(d3.treemapBinary)
          .size([this.config.width, this.config.height])
          .round(true)
          .paddingInner(1)

        var data = d3.hierarchy(this.json)
          .eachBefore(function(d) { d.data.id = (d.parent ? d.parent.data.id + "." : "") + d.data.name})
          .sum(function (d) { return d.totalMarineArea })
          .sort(function(a, b) { return b.height - a.height || b.value - a.value })

        this.orderedData = data

        var nodes = treemap(data)

        //color scheme
        var totalItems = nodes.count().value
        var color = d3.scaleLinear().range(['#729099', '#C2E5E9']).domain([0, totalItems - 1])
        
        //build chart
        var cell = svg.selectAll('g')
          .data(nodes.leaves())
          .enter().append('g')
          .attr('id', function(d) { return (d.data.id).replace(/\s|\./g, '-') })
          .attr('class', 'd3-treemap-cell v-interactive-treemap__cell')
          .attr('transform', function(d) { return 'translate(' + d.x0 + ',' + d.y0 + ')' })

        cell.append('rect')
            .attr('width', function(d) { return d.x1 - d.x0 })
            .attr('height', function(d) { return d.y1 - d.y0 })
            .attr('fill', function(d, i) { return color(i) })

        cell.append('clipPath')
            .attr('id', function(d) { return 'clip-' + d.data.id })
            .append('use')
            .attr('xlink:href', function(d) { return '#' + d.data.id })

        cell.append('text')
          .attr('clip-path', function(d) { return 'url(#clip-' + d.data.id + ')' })
          .attr('transform', function(d) { 
              x = (d.x1 - d.x0)/2
              y = (d.y1 - d.y0)/2
              return 'translate(' + x + ',' + y + ')'
            }
          )
          .attr('text-anchor', 'middle')
          .selectAll('tspan')
          .data(function(d) { return d.data.name.split(/(?=[A-Z][^A-Z])/g) })
          .enter().append('tspan')
          .style('fill', 'white')
          .style('font-family', 'sans-serif')
          .text(function(d) { return d })

        if(this.interactive){
          cell.on('mouseenter touchstart', (d) => { this.mouseenter(d.data) })
        }
      },

      createSVG(){
        var svg = d3.select('.treemap')
          .append('svg')
          .attr('class', 'u-block')
          .attr('viewBox', '0 0 ' + this.config.width + ' ' + this.config.height)
          .attr('viewport', this.config.width + 'x' + this.config.height)
          .attr('preserveAspectRatio', 'xMidYMid')
          .attr('width', '100%')
          .attr('height', '100%')

        return svg
      },

      mouseenter(data) {
        var activeClass = 'v-interactive-treemap__cell-active'

        $('.d3-treemap-cell').removeClass(activeClass)
        $('#' + (data.id).replace(/\s|\./g, '-')).addClass(activeClass)

        var data = {
          country: data.name,
          totalMarineArea: data.totalMarineArea,
          totalOverseasTerritories: data.totalOverseasTerritories,
          national: data.national,
          nationalPercentage: data.nationalPercentage,
          overseas: data.overseas,
          overseasPercentage: data.overseasPercentage
        }

        this.$emit('mouseenter', data)
      }
    }
  }
</script>
