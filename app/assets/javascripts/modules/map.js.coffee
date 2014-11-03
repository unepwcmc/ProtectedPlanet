window.ProtectedPlanet ||= {}

class ProtectedPlanet.Map
  L.mapbox.accessToken = 'pk.eyJ1IjoidW5lcHdjbWMiLCJhIjoiRXg1RERWRSJ9.taTsSWwtAfFX_HMVGo2Cug'

  CONFIG =
    minZoom: 2
    zoomControl: false
    attributionControl: false

  constructor: (@$mapContainer) ->

  render: ->
    if @$mapContainer.length == 0
      return false

    if ProtectedPlanet.Map.instance?
      ProtectedPlanet.Map.instance.remove()

    config = @$mapContainer.data()

    map = @createMap(@$mapContainer.attr('id'))

    ProtectedPlanet.Maps.BaseLayer.render(map)
    ProtectedPlanet.Maps.Bounds.setToBounds(map, config)
    ProtectedPlanet.Maps.ProtectedAreaOverlay.render(map, config)
    ProtectedPlanet.Maps.Search.showSearchResults(map, config.url)
    if config.animate and !config.url?
      ProtectedPlanet.Maps.Animation.startAnimation(map)

    ProtectedPlanet.Map.instance = map

  createMap: (id) ->
    L.mapbox.map(
      id, 'unepwcmc.ijh17499', CONFIG
    ).addControl(L.control.zoom(position: 'topright'))
