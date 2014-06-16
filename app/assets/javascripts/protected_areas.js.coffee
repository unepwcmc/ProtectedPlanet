$(document).ready ->
  map = L.map('map', {
    center: [51.505, -0.09]
    zoom: 14
  })

  L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png').addTo(map)
  L.tileLayer('http://carbon-tool.cartodb.com/tiles/wdpa_poly_feb2014_0/{z}/{x}/{y}.png').addTo(map)

  window.fitToBounds = (bounds) ->
    mapSize = map.getSize()
    paddingLeft = mapSize.x/5
    map.fitBounds(bounds, {paddingTopLeft: [paddingLeft, 0]})
