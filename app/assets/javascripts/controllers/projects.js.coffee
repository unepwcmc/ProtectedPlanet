initialiseDownloads = ->
  $downloadBtns = [
    $(".download-type-dropdown[data-download-type='project'] a")
  ]

  return false if $downloadBtns.length == 0

  $downloadBtns.forEach( ($btn) ->
    $btn.on('click', (e) ->
      button = $(@)
      e.preventDefault()

      list = button.parents('ul')

      ProtectedPlanet.Downloads.Base.start(
        list.data('download-type'),
        button.data('type'),
        {itemId: list.data('item-id')}
      )
    )
  )

ready = ->
  initialiseDownloads()
  $('.best_in_place').best_in_place()

$(window).load(ready)
$(document).on('page:load', ready)
