$(document).ready( ->
  $landStatsCube = $('#land-stats .cube__inner')
  $marineStatsCube = $('#marine-stats .cube__inner')

  percentageLandCoverage = Math.sqrt($landStatsCube.data('fill-value')*100)
  $landStatsCube.css('height', "#{percentageLandCoverage}%")
  $landStatsCube.css('width', "#{percentageLandCoverage}%")

  percentageMarineCoverage = Math.sqrt($marineStatsCube.data('fill-value')*100)
  $marineStatsCube.css('height', "#{percentageMarineCoverage}%")
  $marineStatsCube.css('width', "#{percentageMarineCoverage}%")

  $pointsPolygonsBar = $('#points-polygons-ratio .horizontal-bar__inner')

  percentagePolygons = $pointsPolygonsBar.data('fill-value')
  $pointsPolygonsBar.css('width', "#{percentagePolygons}%")
)
