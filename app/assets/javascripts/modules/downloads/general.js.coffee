define('downloads_general', ['downloads_base'], (Base) ->
  class General extends Base
    constructor: (@type, @opts={}) ->
      super(@type, @opts)
      @domain = 'general'
      @completedDownloadTemplate = -> $('#general-download-complete-modal-template').html()

    submitDownload: (next) ->
      @trackDownload("Submit - #{@type}", @opts.itemId)
      $.post(@constructor.CREATION_PATH, {AUTH_TOKEN: @authToken, id: @opts.itemId, domain: @domain}, next)

    trackDownloadClick: (ev) =>
      @trackDownload("Download Click - #{@type}", @opts.itemId)

  return General
)
