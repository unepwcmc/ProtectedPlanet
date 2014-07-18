class @PageInitialiser

  initialiseMap: ($mapContainer) ->
    return false if $mapContainer.length == 0

    map = new ProtectedAreaMap($mapContainer)

    tileConfig = 
      wdpaId: $mapContainer.attr('data-wdpa-id')
      iso3: $mapContainer.attr('data-iso3')
      regionName: $mapContainer.attr('data-region-name')
    map.addCartodbTiles tileConfig

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

  initialiseProtectedCoverageViz: ($vizContainer) ->
    return false if $vizContainer.length == 0 or not Modernizr.svg?
    $vizContainer.find('.viz').each (idx, el) ->
      value = $(el).attr('data-value')
      return if typeof +value isnt "number" or +value is isNaN
      data = [
        {
          value: value
          color: $(el).attr('data-colour')
        }
        {
          value: 100 - value
          color: "#d2d2db"
          is_background: true
        }
      ]
      annularSectorGenerator data, el, 160, 160

    
