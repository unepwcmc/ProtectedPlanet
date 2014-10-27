initialiseSearchDownloads = ->
  $downloadBtn = $('.download-search')
  return false if $downloadBtn.length == 0

  $downloadBtn.on('click', (e) ->
    SearchDownload.start(
      $downloadBtn.data('create-from'), $downloadBtn.data('poll-from')
    )
    e.preventDefault()
  )

ready = ->
  new window.ProtectedPlanet.Map($('#map'), ProtectedPlanet.SearchMap)

  initialiser = new window.ProtectedPlanet.PageInitialiser()
  initialiseSearchDownloads()

$(document).ready(ready)
$(document).on('page:load', ready)
