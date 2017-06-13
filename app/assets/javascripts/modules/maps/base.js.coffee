define(
  'map',
  ['base_layer', 'interactive', 'bounds', 'protected_area_overlay'],
  (BaseLayer, Interactive, Bounds, ProtectedAreaOverlay) ->
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

        if config.wdpaIds
          @updateMap(config.wdpaIds)
        else
          Interactive.listen(@map)
          ProtectedAreaOverlay.render(@map, config)

      createMap: (id) ->
        L.mapbox.map(
          id, 'unepwcmc.l8gj1ihl', CONFIG
        ).addControl(L.control.zoom(position: 'bottomright'))

      COLORS = ['#71a32b', '#c6e3cb', '#80cbd1', '#40aed2', '#3383b9', '#27589e', '#1b2c85']
      updateMap: (ids) ->
        @shownIds = ids
        @resetProtectedAreas()
        @$mapContainer.data('wdpa-ids', ids)

        for wdpaid, index in ids
          @loadProtectedArea(wdpaid, index)

      updateBounds: (networkId) ->
        $.getJSON("/api/v3/networks/#{networkId}/bounds", (data) =>
          bounds = {boundFrom: data[0], boundTo: data[1]}
          Bounds.setToBounds(@map, bounds)
        )

      resetProtectedAreas: ->
        # remove tooltip if any
        if window.ProtectedPlanet?.Map.marker?
          @map.removeLayer window.ProtectedPlanet.Map.marker

        # remove geometries from the map
        for paLayer in (window.ProtectedPlanet.Map.protectedAreas || [])
          @map.removeLayer(paLayer) unless typeof paLayer == 'undefined'

        # annihilate stored protected areas
        window.ProtectedPlanet.Map.protectedAreas = []

      loadProtectedArea: (wdpaid, index) ->
        $.getJSON("/api/v3/protected_areas/#{wdpaid}/geojson", (data) =>
          unless wdpaid not in @shownIds
            pa_layer = L.geoJSON(data, style: ->
              {fillOpacity: .6, weight: 1, fillColor: COLORS[index], color: "#FF6600"}
            ).addTo(@map)

            window.ProtectedPlanet.Map.protectedAreas[index] = pa_layer
        )

    return Map

)
