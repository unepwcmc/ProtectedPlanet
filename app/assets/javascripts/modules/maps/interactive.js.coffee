window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Maps ||= {}

class ProtectedPlanet.Maps.Interactive
  constructor: (@map) ->

  listen: ->
    @map.on('click', @handleMapClick)

  addMarker: (coords, protected_area) =>
    if @currentMarker?
      @map.removeLayer @currentMarker

    @currentMarker = L.marker(coords).
      addTo(@map).
      bindPopup(@linkTo(protected_area)).
      openPopup()

  handleMapClick: (e) =>
    coords = e.latlng
    params = {
      lon: coords.lat
      lat: coords.lng
      distance: 1
    }

    $.get('/api/search/by_point', params, (data) =>
      if data.length > 0
        @addMarker(coords, data[0])
    )

  linkTo: (pa) ->
    "<a href=\"/#{pa.wdpa_id}\">#{pa.name}</a>"
