class @ProtectedAreaMap
  constructor: (elementId) ->
    @map = L.map(elementId, {scrollWheelZoom: false})

    L.tileLayer('http://api.tiles.mapbox.com/v3/unepwcmc.ijh17499/{z}/{x}/{y}.png').addTo(@map)
    L.tileLayer('http://carbon-tool.cartodb.com/tiles/wdpa_poly_feb2014_0/{z}/{x}/{y}.png').addTo(@map)

  fitToBounds: (bounds) ->
    mapSize = @map.getSize()
    paddingLeft = mapSize.x/5
    @map.fitBounds(bounds, {
      paddingTopLeft: [paddingLeft, 50],
      paddingBottomRight: [0, 50]
    })

  setZoomControlPosition: (position) ->
    @map.zoomControl.setPosition(position)
