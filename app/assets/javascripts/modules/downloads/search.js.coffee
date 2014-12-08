window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Downloads ||= {}

class ProtectedPlanet.Downloads.Search extends ProtectedPlanet.Downloads.Base
  constructor: (@type, @opts={}) ->
    super(@type, @opts)
    @domain = 'search'

  submitDownload: (next) ->
    $.post(@constructor.CREATION_PATH + window.location.search, {domain: @domain}, next)

