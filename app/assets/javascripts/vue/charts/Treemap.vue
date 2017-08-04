<template>
  <div>
    <div class="treemap"></div>
  </div>
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
          width: 600,
          height: 400
        },
        totalArea: 0,
      }
    },

    mounted() {
      this.renderChart()
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
          .sum(function (d) { return d.size })
          .sort(function(a, b) { return b.height - a.height || b.value - a.value })

        this.totalArea = data.value

        var nodes = treemap(data)

        //color scheme
        var totalItems = nodes.count().value
        var color = d3.scaleLinear().range(['#729099', '#C2E5E9']).domain([0, totalItems - 1])
        
        //build chart
        var cell = svg.selectAll("g")
          .data(nodes.leaves())
          .enter().append("g")
          .attr("transform", function(d) { return "translate(" + d.x0 + "," + d.y0 + ")" })

        cell.append("rect")
            .attr("id", function(d) { return d.data.id })
            .attr("width", function(d) { return d.x1 - d.x0 })
            .attr("height", function(d) { return d.y1 - d.y0 })
            .attr("fill", function(d, i) { return color(i) })

        cell.append("clipPath")
            .attr("id", function(d) { return "clip-" + d.data.id })
            .append("use")
            .attr("xlink:href", function(d) { return "#" + d.data.id })

        cell.append("text")
          .attr("clip-path", function(d) { return "url(#clip-" + d.data.id + ")" })
          .attr('transform', function(d) { 
              x = (d.x1 - d.x0)/2
              y = (d.y1 - d.y0)/2
              return 'translate(' + x + ',' + y + ')'
            }
          )
          .attr('text-anchor', 'middle')
          .selectAll("tspan")
          .data(function(d) { return d.data.name.split(/(?=[A-Z][^A-Z])/g) })
          .enter().append("tspan")
          .style('fill', 'white')
          .style('font-family', 'sans-serif')
          .text(function(d) { return d })

        if(this.interactive){
          cell.on('mouseover', (d) => {
            this.mouseover(d.data.size)
          })
            .on('mouseleave', this.mouseleave)
        }
      },

      createSVG(){
        var svg = d3.select('.treemap')
          .append('svg')
          .attr('viewBox', '0 0 ' + this.config.width + ' ' + this.config.height)
          .attr('viewport', this.config.width + 'x' + this.config.height)
          .attr('preserveAspectRatio', 'xMidYMid')
          .attr('width', '100%')
          .attr('height', '100%')

        return svg
      },

      setTotalArea() {

      },

      mouseover(size) {
        var data = {
          percent: (size/this.totalArea)*100,
          km: size
        }

        this.$emit('mouseover', data)
      },

      mouseleave() {
        this.$emit('mouseleave')
      }
    }
  }
</script>
