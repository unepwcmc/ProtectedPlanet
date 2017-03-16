define('downloads_protected_area', ['downloads_base'], (Base) ->
  class ProtectedArea extends Base
    constructor: (@type, @opts={}) ->
      super(@type, @opts)
      @domain = 'protected_area'

    submitDownload: (next) ->
      @trackDownload("Submit - #{@type}", @opts.itemId)
      $.post(@constructor.CREATION_PATH, {
        AUTH_TOKEN: @authToken,
        wdpa_id: @opts.itemId,
        domain: @domain
      }, next)

    trackDownloadClick: (ev) =>
      @trackDownload("Download Click - #{@type}", @opts.itemId)

  return ProtectedArea
)

