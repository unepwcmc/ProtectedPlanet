class @PageInitialiser

  initialiseMap: ($mapContainer) ->
    return false if $mapContainer.length == 0

    map = new ProtectedAreaMap($mapContainer)

    wdpaId = $mapContainer.attr('data-wdpa-id')
    if wdpaId?
      map.addWdpaTiles(wdpaId)

    zoomControl = $mapContainer.attr('data-zoom-control')
    if zoomControl?
      map.setZoomControl(zoomControl)

    boundFrom = $mapContainer.attr('data-bound-from')
    boundTo = $mapContainer.attr('data-bound-to')
    if boundFrom? and boundTo?
      withPadding = $mapContainer.attr('data-padding-enabled')
      map.fitToBounds(
        [boundFrom, boundTo].map(JSON.parse),
        withPadding
      )

    # Geolocation
    locationEnabled = $mapContainer.attr('data-geolocation-enabled')
    if locationEnabled?
      map.locate()

  initialiseDownloadModal: ($modalContainer) ->
    downloadModal = new DownloadModal($modalContainer)
    $('.btn-download').on('click', (e) ->
      downloadModal.buildLinksFor(@getAttribute('data-download-object'))
      downloadModal.show()
      e.preventDefault()
    )

  initialiseAboutModal: ($modalContainer) ->
    aboutModal = new AboutModal($modalContainer)
    $('.btn-about').on('click', (e) ->
      aboutModal.show()
      e.preventDefault()
    )
