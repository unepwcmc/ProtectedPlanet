initialiseSearchDownloads = ->
  $downloadBtn = $('.download-search')
  return false if $downloadBtn.length == 0

  $downloadBtn.on('click', (e) ->
    SearchDownload.start(
      $downloadBtn.data('create-from'), $downloadBtn.data('poll-from')
    )
    e.preventDefault()
  )

setupSearch = ->
  new ProtectedPlanet.Search.Bar($('.search-bar'), $('.icon.search'))
  new ProtectedPlanet.Search.Sidebar($('.search-map-filters'), {
    relatedEls: [$('.search-parent #map'), $('.search-grid')]
  })

ready = ->
  new ProtectedPlanet.Map($('#map')).render()
  new ProtectedPlanet.Dropdown($('.btn-search-download'), $('.download-type-dropdown'))

  initialiseSearchDownloads()
  setupSearch()

$(document).ready(ready)
$(document).on('page:load', ready)
