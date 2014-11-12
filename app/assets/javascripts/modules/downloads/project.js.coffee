window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Downloads ||= {}

class ProtectedPlanet.Downloads.Project extends ProtectedPlanet.Downloads.Base
  start: ->
    @submitDownload( (download) =>
      if download.link?
        @showDownloadModal(download)
      else
        @pollDownload(download, @showDownloadModal)
    )

  submitDownload: (next) =>
    $.get(@constructor.CREATION_PATH + "/#{@opts.itemId}?domain=project", next)

  showDownloadModal: (download) =>
    @generationModal.showDownloadLink(download[@type])

  pollDownload: (download, next) =>
    checkPolling = (data) =>
      if data.status == 'completed'
        window.clearInterval(intervalId)
        next(data)

    intervalId = setInterval( =>
      $.get("#{@constructor.POLLING_PATH}", {token: download.token}, checkPolling)
    , @constructor.POLLING_INTERVAL)
