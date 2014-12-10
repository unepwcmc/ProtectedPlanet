DEPENDENCIES = [
  'mapbox', './maps/base_layer', './maps/interactive', './maps/bounds',
  './maps/protected_area_overlay', './maps/search'
]

define(DEPENDENCIES, (mapbox, BaseLayer, Interactive, Bounds,
  ProtectedAreaOverlay, Search) ->
  class Map
    L.mapbox.accessToken = 'pk.eyJ1IjoidW5lcHdjbWMiLCJhIjoiRXg1RERWRSJ9.taTsSWwtAfFX_HMVGo2Cug'

    CONFIG =
      minZoom: 2
      zoomControl: false
      attributionControl: false

    constructor: (@$mapContainer) ->

    render: ->
      if @$mapContainer.length == 0
        return false

      config = @$mapContainer.data()

      map = @createMap(@$mapContainer.attr('id'))

      Interactive.listen(map)
      BaseLayer.render(map)
      Bounds.setToBounds(map, config)
      ProtectedAreaOverlay.render(map, config)
      Search.showSearchResults(map, config.url)

      window.ProtectedPlanet ||= {}
      window.ProtectedPlanet.Map = {'instance': map}

    createMap: (id) ->
      L.mapbox.map(
        id, 'unepwcmc.ijh17499', CONFIG
      ).addControl(L.control.zoom(position: 'topright'))

  return Map
)
