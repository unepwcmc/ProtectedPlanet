define('downloads_base', ['download_generation_modal'], (DownloadGenerationModal) ->
  class Base
    @CREATION_PATH: '/downloads'
    @POLLING_PATH: '/downloads/poll'
    @POLLING_INTERVAL: 250

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

  return Base
)
