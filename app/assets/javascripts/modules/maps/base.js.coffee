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

        @map = @createMap(@$mapContainer.attr('id'))

        unless config.scrollWheelZoom?
          @map.scrollWheelZoom.disable()

        window.ProtectedPlanet ||= {}
        window.ProtectedPlanet.Map = {instance: @map, object: @}
        window.ProtectedPlanet.Maps ||= {}
        window.ProtectedPlanet.Maps[@$mapContainer.attr("id")] = {
          "instance": @map
        }
        
        BaseLayer.render(@map, config)
        Bounds.setToBounds(@map, config)
        Interactive.listen(@map)
        ProtectedAreaOverlay.render(@map, config)
        Search.showSearchResults(@map, config.url)

      createMap: (id) ->
        L.mapbox.map(
          id, 'unepwcmc.l8gj1ihl', CONFIG
        ).addControl(L.control.zoom(position: 'bottomright'))

      updateMap: (ids) ->
        @$mapContainer.data('wdpa-ids', ids)
        config = @$mapContainer.data()
        Interactive.listen(@map)
        ProtectedAreaOverlay.render(@map, config)

    return Map
)
