window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Downloads ||= {}

class ProtectedPlanet.Downloads.Search extends ProtectedPlanet.Downloads.Base
  constructor: (@ext, @opts={}) ->
    super(@ext, @opts)
    @domain = 'search'

  submitDownload: (next) ->
    $.post(@constructor.CREATION_PATH + window.location.search, (data) ->
      next(data.token)
    )

  completed: (download) ->
    download.status == 'completed'
