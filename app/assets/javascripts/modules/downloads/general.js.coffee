window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Downloads ||= {}

class ProtectedPlanet.Downloads.General extends ProtectedPlanet.Downloads.Base
  constructor: (@ext, @opts={}) ->
    super(@ext, @opts)
    @domain = 'general'

  submitDownload: (next) ->
    $.get(
      @constructor.CREATION_PATH + "/#{@opts.itemId}",
      {domain: @domain, ext: @ext}
      next
    )

  completed: (download) ->
    true
