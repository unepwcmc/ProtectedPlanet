class @PageInitialiser
  DEFAULT_ZOOM_CONTROLS_POS = 'topright'

  initialiseMap: (mapContainerId) ->
    mapEl = $("##{mapContainerId}")
    return false unless mapEl?

    map = new ProtectedAreaMap(mapContainerId)

    zoomControlsPosition = mapEl.attr('data-zoom-controls')
    map.setZoomControlPosition(zoomControlsPosition || DEFAULT_ZOOM_CONTROLS_POS)

    boundFrom = mapEl.attr('data-bound-from')
    boundTo = mapEl.attr('data-bound-to')
    if boundFrom? and boundTo?
      map.fitToBounds([
        JSON.parse(boundFrom),
        JSON.parse(boundTo)
      ])


  initialiseDownloadModal: ->
    downloadModal = new DownloadModal()
    $('body').append(downloadModal.$el)
    $('.btn-download').on('click', (e) ->
      downloadModal.buildLinksFor(@getAttribute('data-download-object'))
      downloadModal.show()
      e.preventDefault()
    )

