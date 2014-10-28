window.ProtectedPlanet ||= {}

class ProtectedPlanet.SearchMap extends ProtectedPlanet.Map
  constructor: (@map, @config) ->
    @getPoints( (points) =>
      markers = L.markerClusterGroup(
        showCoverageOnHover: false
      ).addLayers(points)
      @map.addLayer(markers)
    )

  getPoints: (callback) ->
    $.get(@config.url, (protected_areas) =>
      markerList = []

      for pa in protected_areas
        marker = L.marker(
          L.latLng(pa.the_geom_latitude, pa.the_geom_longitude),
          { title: pa.name }
        )

        marker.bindPopup(@linkTo(pa))
        markerList.push(marker)

      @fitToResults(protected_areas)
      callback(markerList)
    )

  fitToResults: (points) ->
    lats = points.map((p) -> parseFloat(p.the_geom_latitude))
    lons = points.map((p) -> parseFloat(p.the_geom_longitude))

    maxLat = Math.max.apply(Math, lats)
    minLat = Math.min.apply(Math, lats)
    maxLon = Math.max.apply(Math, lons)
    minLon = Math.min.apply(Math, lons)

    @fitToBounds([[maxLat,maxLon],[minLat,minLon]])

  linkTo: (pa) ->
    "<a href=\"/#{pa.wdpa_id}\">#{pa.name}</a>"
