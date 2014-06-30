class @PageInitialiser

  initialiseMap: (mapContainerId) ->
    return false if $("##{mapContainerId}").length == 0

    map = new ProtectedAreaMap(mapContainerId)

    zoomControl = map.el.attr('data-zoom-control')
    if zoomControl?
      map.setZoomControl(zoomControl)

    boundFrom = map.el.attr('data-bound-from')
    boundTo = map.el.attr('data-bound-to')
    if boundFrom? and boundTo?
      withPadding = map.el.attr('data-padding-enabled')
      map.fitToBounds(
        [boundFrom, boundTo].map(JSON.parse),
        withPadding
      )

    # Geolocation
    locationEnabled = map.el.attr('data-geolocation-enabled')
    if locationEnabled?
      map.locate()

  initialiseDownloadModal: ->
    downloadModal = new DownloadModal()
    $('body').append(downloadModal.$el)
    $('.btn-download').on('click', (e) ->
      downloadModal.buildLinksFor(@getAttribute('data-download-object'))
      downloadModal.show()
      e.preventDefault()
    )

