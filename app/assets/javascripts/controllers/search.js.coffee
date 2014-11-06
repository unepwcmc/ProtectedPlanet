initialiseSearchDownloads = ->
  $downloadBtns = $('.download-type-dropdown a')
  return false if $downloadBtns.length == 0

  $downloadBtns.on('click', (e) ->
    e.preventDefault()

    button = $(e.target)
  )

setupSearch = ->
  new ProtectedPlanet.Search.Pagination('.search-grid ul', '.result')
  new ProtectedPlanet.Search.Sidebar($('.search-map-filters'), {
    relatedEls: [$('.search-parent #map'), $('.search-grid')]
  })

ready = ->
  new ProtectedPlanet.Map($('#map')).render()

  initialiseSearchDownloads()
  setupSearch()

$(document).ready(ready)
$(document).on('page:load', ready)
