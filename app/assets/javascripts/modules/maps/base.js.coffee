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
        @updateMap(config.wdpaIds)
        Search.showSearchResults(@map, config.url)

      createMap: (id) ->
        L.mapbox.map(
          id, 'unepwcmc.l8gj1ihl', CONFIG
        ).addControl(L.control.zoom(position: 'bottomright'))

      COLORS = ['#71a32b', '#c6e3cb', '#80cbd1', '#40aed2', '#3383b9', '#27589e', '#1b2c85']
      updateMap: (ids) ->
        window.ProtectedPlanet.Map.protected_areas = []

        @$mapContainer.data('wdpa-ids', ids)

        config = @$mapContainer.data()
        Interactive.listen(@map)

        loadProtectedArea = (wdpaid, index) =>
          $.getJSON("/api/v3/protected_areas/#{wdpaid}/geojson", (data) =>

            pa_layer = L.geoJSON(data, style: ->
              {fillOpacity: .6, weight: 1, fillColor: COLORS[index], color: "#FF6600"}
            ).addTo(@map)

            window.ProtectedPlanet.Map.protected_areas.push(pa_layer)
          )

        for wdpaid, index in ids
          loadProtectedArea(wdpaid, index)

    return Map
)
