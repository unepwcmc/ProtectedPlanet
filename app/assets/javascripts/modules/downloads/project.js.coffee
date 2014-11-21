window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Downloads ||= {}

class ProtectedPlanet.Downloads.Project extends ProtectedPlanet.Downloads.Base
  constructor: (@ext, @opts={}) ->
    super(@ext, @opts)
    @domain = 'project'

  submitDownload: (next) =>
    $.get(@constructor.CREATION_PATH + "/#{@opts.itemId}?domain=project", next)

  completed: (download) ->
    download.status == 'completed'
