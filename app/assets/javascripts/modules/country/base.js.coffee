$(document).ready( ->
  $landStatsCube = $('#land-stats .cube__inner')
  $marineStatsCube = $('#marine-stats .cube__inner')

  percentageLandCoverage = $landStatsCube.data('fill-value')
  $landStatsCube.css('height', "#{percentageLandCoverage}%")
  $landStatsCube.css('width', "#{percentageLandCoverage}%")

  percentageMarineCoverage = $marineStatsCube.data('fill-value')
  $marineStatsCube.css('height', "#{percentageMarineCoverage}%")
  $marineStatsCube.css('width', "#{percentageMarineCoverage}%")

  $pointsPolygonsBar = $('#points-polygons-ratio .horizontal-bar__inner')

  percentagePolygons = $pointsPolygonsBar.data('fill-value')
  $pointsPolygonsBar.css('width', "#{percentagePolygons}%")

  $('.table--sortable').tablesorter(
    cssAsc: 'table__column--sort-asc'
    cssDesc: 'table__column--sort-desc'
  )

  $countriesSelect = $('#countries-select')
  return false if $countriesSelect.length == 0

  $countriesSelect.select2(containerCss: {width: '200px'})
  $countriesSelect.on 'change', (ev) ->
    iso = $('.factsheet').data('countryIso')
    iso_to_compare = ev.added.id

    window.location = "/country/#{iso}/compare/#{iso_to_compare}"
)
