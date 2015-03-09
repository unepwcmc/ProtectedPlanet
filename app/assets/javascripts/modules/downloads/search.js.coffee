define('downloads_search', ['downloads_base'], (Base) ->
  class Search extends Base
    constructor: (@type, @opts={}) ->
      super(@type, @opts)
      @domain = 'search'

    submitDownload: (next) ->
      @trackDownload("Submit - #{@type}", window.location.search)
      $.post(@constructor.CREATION_PATH + window.location.search, {AUTH_TOKEN: @authToken, domain: @domain}, next)

    trackDownloadClick: (ev) =>
      @trackDownload("Download Click - #{@type}", window.location.search)

  return Search
)
