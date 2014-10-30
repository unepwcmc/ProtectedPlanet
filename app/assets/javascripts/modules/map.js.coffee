window.ProtectedPlanet ||= {}

class ProtectedPlanet.Map
  L.mapbox.accessToken = 'pk.eyJ1IjoidW5lcHdjbWMiLCJhIjoiRXg1RERWRSJ9.taTsSWwtAfFX_HMVGo2Cug'

  constructor: (@$mapContainer) ->

  render: ->
    return false if @$mapContainer.length == 0

    config = @$mapContainer.data()
    map = @createMap(@$mapContainer.attr('id'))

    ProtectedPlanet.Maps.BaseLayer.render(map)
    ProtectedPlanet.Maps.Bounds.setToBounds(map, config)
    ProtectedPlanet.Maps.ProtectedAreaOverlay.render(map, config)
    ProtectedPlanet.Maps.Search.showSearchResults(map, config.url)
    ProtectedPlanet.Maps.Animation.startAnimation(map) if config.animate

  createMap: (id) ->
    L.mapbox.map(
      id,
      'unepwcmc.ijh17499',
      {minZoom: 2, zoomControl: false, attributionControl: false}
    ).addControl(L.control.zoom(position: 'topright'))
