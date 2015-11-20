define(
  'map',
  ['base_layer', 'interactive', 'bounds', 'protected_area_overlay', 'search'],
  (BaseLayer, Interactive, Bounds, ProtectedAreaOverlay, Search) ->
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

        unless config.scrollWheelZoom?
          map.scrollWheelZoom.disable()

        BaseLayer.render(map)
        Bounds.setToBounds(map, config)
        Interactive.listen(map)
        ProtectedAreaOverlay.render(map, config)
        Search.showSearchResults(map, config.url)

        window.ProtectedPlanet ||= {}
        window.ProtectedPlanet.Map = {'instance': map}

      createMap: (id) ->
        L.mapbox.map(
          id, 'unepwcmc.l8gj1ihl', CONFIG
        ).addControl(L.control.zoom(position: 'bottomright'))

    return Map
)
