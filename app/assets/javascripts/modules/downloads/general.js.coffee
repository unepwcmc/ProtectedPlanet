window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Downloads ||= {}

class ProtectedPlanet.Downloads.General extends ProtectedPlanet.Downloads.Base
  constructor: (@ext, @opts={}) ->
    super(@ext, @opts)
    @domain = 'general'

  submitDownload: (next) ->
    $.post(
      @constructor.CREATION_PATH + "/#{@opts.itemId}",
      {domain: @domain, ext: @ext}
      next
    )
