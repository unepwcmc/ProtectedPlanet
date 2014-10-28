window.ProtectedPlanet ||= {}

class window.ProtectedPlanet.PageInitialiser
  constructor: ->
    @initialiseDownloadModal($('body'))
    @initialiseAboutModal($('body'))

  initialiseDownloadModal: ($modalContainer) ->
    downloadModal = new DownloadSelectionModal($modalContainer)
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
