define(
  'map',
  ['base_layer', 'interactive', 'bounds', 'protected_area_overlay'],
  (BaseLayer, Interactive, Bounds, ProtectedAreaOverlay) ->
    class Map
      L.mapbox.accessToken = 'pk.eyJ1IjoidW5lcHdjbWMiLCJhIjoiRXg1RERWRSJ9.taTsSWwtAfFX_HMVGo2Cug'

      POLYGONS_TABLE = 'wdpa_poly'
      POINTS_TABLE   = 'wdpa_point'

      CONFIG =
        minZoom: 2
        zoomControl: false
        attributionControl: true

      constructor: (@$mapContainer) ->

      render: ->
        if @$mapContainer.length == 0
          return false

        config = @$mapContainer.data()

        @map = @createMap(@$mapContainer.attr('id'), @$mapContainer.data('zoom-position'))

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

      createMap: (id, position = "bottomright") ->
        L.mapbox.map(
          id, 'unepwcmc.l8gj1ihl', CONFIG
        ).addControl(L.control.zoom(position: position))

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

      resizeMap: ->
        @map.invalidateSize();

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
        query = "
          SELECT ST_AsGeoJSON(the_geom) as the_geom
          FROM #{POLYGONS_TABLE}
          WHERE wdpa_poly.wdpaid = #{wdpaid}

          UNION ALL

          SELECT ST_AsGeoJSON(the_geom) as the_geom
          FROM #{POINTS_TABLE}
          WHERE wdpa_point.wdpaid = #{wdpaid}
        "
        $.getJSON("https://carbon-tool.carto.com/api/v2/sql?q=#{query}", (data) =>
          unless wdpaid not in @shownIds
            unless data.rows[0]
              console.log('No geojson data found')
            else
              the_geom = JSON.parse(data.rows[0].the_geom)
              pa_layer = L.geoJSON(the_geom, style: =>
                {fillOpacity: .6, weight: 1, fillColor: @getFillColor(index), color: "#FF6600"}
              ).addTo(@map)

              window.ProtectedPlanet.Map.protectedAreas[index] = pa_layer
        )

      getFillColor: (index) ->
        COLORS = ['#71a32b', '#1b2c85']
        return if index == 0 then COLORS[0] else COLORS[1]

    return Map

)
