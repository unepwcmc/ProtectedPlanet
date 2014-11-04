window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Search ||= {}

class ProtectedPlanet.Search.Download
  POLLING_INTERVAL = 250

  @start: (creationPath, pollingPath) ->
    new SearchDownload(creationPath, pollingPath).start()

  constructor: (@creationPath, @pollingPath, @opts={mainContainer: $('body')}) ->
    @generationModal = new DownloadGenerationModal(@opts.mainContainer)
    @selectionModal = new DownloadSelectionModal(@opts.mainContainer)

  start: ->
    @submitDownload( (token) =>
      @generationModal.show()
      @pollDownload(token, (download) =>
        @generationModal.hide()

        @selectionModal.buildLinksFor(download.filename)
        @selectionModal.show()
      )
    )


  submitDownload: (next) ->
    $.post(@creationPath + window.location.search, (data) ->
      next(data.token)
    )

  pollDownload: (token, next) ->
    intervalId = setInterval( =>
      $.getJSON("#{@pollingPath}?token=#{token}", (download) ->
        if download.status == 'completed'
          window.clearInterval(intervalId)
          next(download)
      )
    , POLLING_INTERVAL)
