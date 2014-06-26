class ProtectedAreaMap
  constructor: (elementId) ->
    @map = L.map(elementId, {scrollWheelZoom: false})
    @map.zoomControl.setPosition('topright')

    L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png').addTo(@map)
    L.tileLayer('http://carbon-tool.cartodb.com/tiles/wdpa_poly_feb2014_0/{z}/{x}/{y}.png').addTo(@map)

  fitToBounds: (bounds) ->
    mapSize = @map.getSize()
    paddingLeft = mapSize.x/5
    @map.fitBounds(bounds, {
      paddingTopLeft: [paddingLeft, 50],
      paddingBottomRight: [0, 50]
    })

ready = ->
  # Map initialisation
  mapContainerId = 'map'
  mapEl = $("##{mapContainerId}")
  if mapEl?
    map = new ProtectedAreaMap(mapContainerId)

    boundFrom = mapEl.attr('data-bound-from')
    boundTo = mapEl.attr('data-bound-to')
    if boundFrom? and boundTo?
      map.fitToBounds([
        JSON.parse(boundFrom),
        JSON.parse(boundTo)
      ])

  # Download Modal initialisation
  downloadModal = new DownloadModal()
  $('body').append(downloadModal.$el)
  $('.btn-download').on('click', (e) ->
    downloadModal.buildLinksFor(@getAttribute('data-download-object'))
    downloadModal.show()
    e.preventDefault()
  )


$(document).ready(ready)
$(document).on('page:load', ready)

