initialiseSearchDownloads = ->
  $downloadBtns = $('.download-type-dropdown a')
  return false if $downloadBtns.length == 0

  $downloadBtns.on('click', (e) ->
    e.preventDefault()

    button = $(e.target)
    ProtectedPlanet.Search.Download.start(button.data('type'))
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
