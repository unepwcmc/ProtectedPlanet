define('downloads_search', ['downloads_base'], (Base) ->
  class Search extends Base
    constructor: (@type, @opts={}) ->
      super(@type, @opts)
      @domain = 'search'

    submitDownload: (next) ->
      $.post(@constructor.CREATION_PATH + window.location.search, {AUTH_TOKEN: @authToken, domain: @domain}, next)

  return Search
)
