window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Search ||= {}

class ProtectedPlanet.Search.Download
  CREATION_PATH = '/downloads'
  POLLING_PATH = '/downloads/poll'
  POLLING_INTERVAL = 250

  @start: (type) ->
    new ProtectedPlanet.Search.Download(type).start()

  constructor: (@type, @opts={mainContainer: $('#download-modal')}) ->
    @generationModal = new DownloadGenerationModal(@opts.mainContainer)

  start: ->
    @submitDownload( (token) =>
      @generationModal.show()
      @pollDownload(token, (download) =>
        @generationModal.showDownloadLink(download.filename, @type)
      )
    )

  submitDownload: (next) ->
    $.post(CREATION_PATH + window.location.search, (data) ->
      next(data.token)
    )

  pollDownload: (token, next) ->
    intervalId = setInterval( =>
      $.getJSON("#{POLLING_PATH}?token=#{token}", (download) ->
        if download.status == 'completed'
          window.clearInterval(intervalId)
          next(download)
      )
    , POLLING_INTERVAL)
