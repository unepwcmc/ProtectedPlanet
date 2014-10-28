window.ProtectedPlanet ||= {}

class ProtectedPlanet.SearchMap extends ProtectedPlanet.Map
  constructor: (@map, @config) ->
    @getPoints( (points) =>
      markers = L.markerClusterGroup({chunkedLoading: true}).addLayers(points)
      @map.addLayer(markers)
    )

  getPoints: (callback) ->
    $.get(@config.url, (points) =>
      markerList = []

      for point in points
        marker = L.marker(
          L.latLng(point.the_geom_latitude, point.the_geom_longitude),
          { title: point.name }
        )

        marker.bindPopup(point.name)
        markerList.push(marker)

      @fitToResults(points)
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
