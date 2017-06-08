define('interactive', [], () ->
  class Interactive
    constructor: (@map) ->
      if window.ProtectedPlanet?.Map.marker?
        @map.removeLayer window.ProtectedPlanet.Map.marker

    @listen: (map) ->
      new Interactive(map).listen()

    listen: ->
      @map.on('click', @handleMapClick)

    addMarker: (coords, protected_area) =>
      if window.ProtectedPlanet.Map.marker?
        @map.removeLayer window.ProtectedPlanet.Map.marker

      window.ProtectedPlanet.Map.marker = L.marker(coords).
        addTo(@map).
        bindPopup(@linkTo(protected_area)).
        openPopup()

    handleMapClick: (e) =>
      coords = e.latlng
      params = {
        lon: coords.lng
        lat: coords.lat
        distance: 1
      }

      $.get('/api/v3/search/by_point', params, (data) =>
        if data.length > 0
          @addMarker(coords, data[0])
      )

    linkTo: (pa) ->
      "<a href=\"/#{pa.wdpa_id}\">#{pa.name}</a>"

  return Interactive
)
