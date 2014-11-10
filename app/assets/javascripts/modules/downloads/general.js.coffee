window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Downloads ||= {}

class ProtectedPlanet.Downloads.General extends ProtectedPlanet.Downloads.Base
  start: ->
    @submitDownload( (download) =>
      @generationModal.showDownloadLink(download.link)
    )


  submitDownload: (next) ->
    $.get(
      @constructor.CREATION_PATH + "/#{@opts.itemId}",
      {domain: 'general', type: @type}
      next
    )


