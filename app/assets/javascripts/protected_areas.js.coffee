ready = ->
  map = L.map('map', {scrollWheelZoom: false})
  map.zoomControl.setPosition('topright')

  L.tileLayer('http://api.tiles.mapbox.com/v3/unepwcmc.ijh17499/{z}/{x}/{y}.png').addTo(map)
  L.tileLayer('http://carbon-tool.cartodb.com/tiles/wdpa_poly_feb2014_0/{z}/{x}/{y}.png').addTo(map)

  window.fitToBounds = (bounds) ->
    mapSize = map.getSize()
    paddingLeft = mapSize.x/5
    map.fitBounds(bounds, {
      paddingTopLeft: [paddingLeft, 50],
      paddingBottomRight: [0, 50]
    })

$(document).ready(ready)
$(document).on('page:load', ready)
