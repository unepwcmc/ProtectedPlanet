window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Downloads ||= {}

class ProtectedPlanet.Downloads.Search extends ProtectedPlanet.Downloads.Base
  start: ->
    @submitDownload( (token) =>
      @generationModal.initialiseForm(token)
      @generationModal.show()

      @pollDownload(token, (download) =>
        @generationModal.showDownloadLink(JSON.parse(download.links)[@type])
      )
    )

  submitDownload: (next) ->
    $.post(@constructor.CREATION_PATH + window.location.search, (data) ->
      next(data.token)
    )
