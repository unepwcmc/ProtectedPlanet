window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Downloads ||= {}

class ProtectedPlanet.Downloads.Base
  @CREATION_PATH: '/downloads'
  @POLLING_PATH: '/downloads/poll'
  @POLLING_INTERVAL: 250

  @start: (domain, type, opts={}) ->
    DOWNLOADERS =
      'general': ProtectedPlanet.Downloads.General
      'project': ProtectedPlanet.Downloads.Project
      'search':  ProtectedPlanet.Downloads.Search

    new DOWNLOADERS[domain](type, opts).start()

  constructor: (@type, @opts={}) ->
    @opts.mainContainer ||= $('#download-modal')
    @generationModal = new DownloadGenerationModal(@opts.mainContainer)

  start: ->
    @submitDownload( (download) =>
      if @completed(download)
        @showDownloadModal(download)
      else
        @showGenerationModal(download)
        @pollDownload(download.token, @showDownloadModal)
    )

  pollDownload: (token, next) =>
    checkPolling = (data) =>
      if @completed(data)
        window.clearInterval(intervalId)
        next(data)

    intervalId = setInterval( =>
      $.get("#{@constructor.POLLING_PATH}", {token: token, domain: @domain}, checkPolling)
    , @constructor.POLLING_INTERVAL)

  showGenerationModal: (download) =>
    @generationModal.initialiseForm(download.token)
    @generationModal.show()

  showDownloadModal: (download) =>
    @generationModal.showDownloadLink(download.filename, @type)

  completed: (download) ->
    download.status == 'ready'
