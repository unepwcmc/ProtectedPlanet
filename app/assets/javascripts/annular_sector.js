'use strict'

// see:
// https://github.com/mbostock/d3/wiki/SVG-Shapes#arc
// https://github.com/mbostock/d3/wiki/Pie-Layout#pie
// https://developer.mozilla.org/en-US/docs/Web/SVG/Tutorial/Fills_and_Strokes

var annularSectorGenerator = (function() {

  var pi = Math.PI;

  function arc(radius, inner_radius_start, outer_radius_start) {
    return d3.svg.arc()
      .innerRadius(radius - inner_radius_start)
      .outerRadius(radius - outer_radius_start);
  }

  function pie(start_angle, end_angle) {
    var start_angle = (start_angle === void 0) ? 1.2*pi : start_angle,
        end_angle = (end_angle === void 0) ? 2.8*pi : end_angle;
    return d3.layout.pie()
      .sort(null)
      .value(function(d) { return d.value; })
      .startAngle(start_angle)
      .endAngle(end_angle);
  }

  return function(data, selector, width, height, inner_radius_start, outer_radius_start) {
    var radius = Math.min(width, height) / 2,
        inner_radius_start = (inner_radius_start === void 0) ?
          6 : inner_radius_start,
        outer_radius_start = (outer_radius_start === void 0) ?
          6 : outer_radius_start;

    var svg = d3.select(selector).append('svg')
      .attr('width', width)
      .attr('height', height)
    .append('g')
      .attr('transform', 'translate(' + width / 2 + ',' + height / 2 + ')');

    var g = svg.selectAll('.arc')
        .data(pie()(data))
      .enter().append('g')
        .attr('class', 'arc');

    g.append('path')
      .attr('d', arc(radius, inner_radius_start, outer_radius_start))
      .attr('stroke', function(d) { return d.data.color; })
      .attr('stroke-width', 10)
      .attr('stroke-linejoin', 'round');

  }

})();
