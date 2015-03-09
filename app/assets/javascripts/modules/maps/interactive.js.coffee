define('interactive', [], () ->
  class Interactive
    constructor: (@map) ->

    @listen: (map) ->
      new Interactive(map).listen()

    listen: ->
      @map.on('click', @handleMapClick)
      @map.on('dragstart', @handleMapDrag)

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
        lon: coords.lng
        lat: coords.lat
        distance: 1
      }

      $.get('/api/v3/search/by_point', params, (data) =>
        if data.length > 0
          @addMarker(coords, data[0])
      )

    handleMapDrag: =>
      $('.explore').fadeOut()
      $('.download-type-dropdown').fadeOut()

    linkTo: (pa) ->
      "<a href=\"/#{pa.wdpa_id}\">#{pa.name}</a>"

  return Interactive
)
