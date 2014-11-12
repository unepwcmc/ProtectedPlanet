window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Downloads ||= {}

class ProtectedPlanet.Downloads.Project extends ProtectedPlanet.Downloads.Base
  start: ->
    @submitDownload( (download) =>
      if download.links?
        @showDownloadModal(download)
      else
        @pollDownload(download, @showDownloadModal)
    )

  submitDownload: (next) =>
    $.get(@constructor.CREATION_PATH + "/#{@opts.itemId}?domain=project", next)

  showDownloadModal: (download) =>
    @generationModal.showDownloadLink(JSON.parse(download.links)[@type])

  pollDownload: (download, next) =>
    checkPolling = (data) =>
      if data.status == 'completed'
        window.clearInterval(intervalId)
        next(data)

    intervalId = setInterval( =>
      $.get("#{@constructor.POLLING_PATH}", {token: @opts.itemId, domain: 'project'}, checkPolling)
    , @constructor.POLLING_INTERVAL)
