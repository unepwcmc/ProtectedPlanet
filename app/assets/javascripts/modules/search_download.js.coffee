class @SearchDownload
  POLLING_INTERVAL = 250

  @start: (creationPath, pollingPath) ->
    new SearchDownload(creationPath, pollingPath).start()

  constructor: (@creationPath, @pollingPath) ->

  start: ->
    @submitDownload( (token) =>
      #@showGenerationModal()
      #@pollDownload(token, (download) =>
      #  hideGenerationModal()
      #  showSelectionModal()
      #)
    )


  submitDownload: (next) ->
    $.post(@creationPath + window.location.search, (data) ->
      next(data.token)
    )

  pollDownload: (token, next) ->
    intervalId = setInterval( ->
      $.getJSON("#{@pollingPath}?token=#{token}", (json) ->
        console.log(json)
      )
    , POLLING_INTERVAL)
