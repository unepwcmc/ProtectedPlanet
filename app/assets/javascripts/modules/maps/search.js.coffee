define('search', ['bounds'], (Bounds) ->
  class Search
    @showSearchResults: (map, url) ->
      return unless url?
      new Search(map, url)

    constructor: (@map, @url) ->
      @getPoints((points) =>
        markers = L.markerClusterGroup(
          showCoverageOnHover: false
          singleMarkerMode: true
        ).addLayers(points)
        @map.addLayer(markers)
      )

    getPoints: (callback) ->
      $.get(@url, (protected_areas) =>
        markerList = []

        for pa in protected_areas
          marker = L.marker(
            L.latLng(pa.coordinates?[0], pa.coordinates?[1]),
            { title: pa.name }
          )

          marker.bindPopup(@linkTo(pa))
          markerList.push(marker)

        @showResultsCount(protected_areas.length)
        @fitToResults(protected_areas)
        callback(markerList)
      )

    fitToResults: (points) ->
      return if points.length is 0

      lats = points.map((p) -> parseFloat(p.coordinates[0]))
      lons = points.map((p) -> parseFloat(p.coordinates[1]))

      maxLat = Math.max.apply(Math, lats)
      minLat = Math.min.apply(Math, lats)
      maxLon = Math.max.apply(Math, lons)
      minLon = Math.min.apply(Math, lons)

      Bounds.setToBounds(@map, {
        boundFrom: [maxLat, maxLon],
        boundTo: [minLat, minLon]
      })

    showResultsCount: (count) ->
      $('.results-count').html(count)

    linkTo: (pa) ->
      "<a href=\"/#{pa.wdpa_id}\">#{pa.name}</a>"

  return Search
)
