window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Downloads ||= {}

class ProtectedPlanet.Downloads.General extends ProtectedPlanet.Downloads.Base
  constructor: (@type, @opts={}) ->
    super(@type, @opts)
    @domain = 'general'

  submitDownload: (next) ->
    $.post(@constructor.CREATION_PATH, {id: @opts.itemId, domain: @domain}, next)
