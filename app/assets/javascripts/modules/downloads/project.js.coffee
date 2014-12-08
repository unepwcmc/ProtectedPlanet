window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Downloads ||= {}

class ProtectedPlanet.Downloads.Project extends ProtectedPlanet.Downloads.Base
  constructor: (@type, @opts={}) ->
    super(@type, @opts)
    @domain = 'project'

  submitDownload: (next) =>
    $.post(@constructor.CREATION_PATH, {id: @opts.itemId, domain: @domain}, next)
